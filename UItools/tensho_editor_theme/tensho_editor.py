import sys
import os
import math
import io
import hashlib

from lxml import etree
from PIL import Image

from PySide6.QtCore import Qt, QRectF, QPointF, QSize, Signal, QSettings, QSignalBlocker, QTimer, QSaveFile, QIODevice
from PySide6.QtGui import (
    QPixmap, QImage, QPen, QColor, QBrush, QFont, QAction, QPainter,
    QKeySequence, QPainterPath, QPolygonF
)
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QTreeWidget, QTreeWidgetItem,
    QSplitter, QGraphicsView, QGraphicsScene, QGraphicsItem,
    QVBoxLayout, QHBoxLayout, QFormLayout, QLineEdit, QSpinBox,
    QLabel, QPushButton, QComboBox, QFileDialog, QMessageBox,
    QTextEdit, QToolBar, QStatusBar, QGroupBox, QCheckBox,
    QMenu, QInputDialog, QDialog, QDialogButtonBox, QListWidget,
    QListWidgetItem, QTabWidget, QToolButton, QGridLayout, QAbstractItemView, QStyledItemDelegate, QDoubleSpinBox, QAbstractItemDelegate
)


from tensho_editor_lib.commands import (
    Command, CommandStack, capture_element, set_xml_text, XmlEditCommand
)

from tensho_editor_lib.document import (
    get_first_state, get_all_state_titles, get_float, get_int, is_page_title,
    COUNT_CHILD_TAGS, MAX_GEOMETRY, REFERENCE_TAGS, DEFINITION_TAGS,
    canonical_id, owner_entry, identifier_kind, reference_kind, numeric_rule,
    validate_scalar, resolve_reference, count_children, sync_count, inspect_document,
    format_issues, allocate_id, clone_ui_entry, expand_empty_elements, serialize_document,
    DocumentIndex
)

from tensho_editor_lib.resources import ResourceResolver, PixmapCache
from tensho_editor_lib.navigation import belongs_to
from tensho_editor_lib.navigation_ui import NavigationTarget
from tensho_editor_lib.navigation_controller import NavigationController
from tensho_editor_lib.assets_ui import AssetsController
from tensho_editor_lib.editing_controller import EditingController
from tensho_editor_lib.recovery_controller import RecoveryController
from tensho_editor_lib.theme import apply_light_theme, color as theme_color, icon as theme_icon, ui_font, code_font


# =========================================================
# 工具函数
# =========================================================


def argb_to_qcolor(value, fallback=QColor(0, 0, 0, 255)):
    try:
        v = int(value)
    except (TypeError, ValueError):
        return fallback
    if v < 0:
        v = v + (1 << 32)
    a = (v >> 24) & 0xFF
    r = (v >> 16) & 0xFF
    g = (v >> 8) & 0xFF
    b = v & 0xFF
    return QColor(r, g, b, a)


# =========================================================
# 画布图元
# =========================================================
class UiEntryItem(QGraphicsItem):
    HANDLE_SIZE = 6
    SNAP_THRESHOLD = 5

    def __init__(self, ui_entry, tga_map, pixmap_cache, editor,
                 parent=None, page_filter=None):
        super().__init__(parent)
        self.ui_entry = ui_entry
        self.tga_map = tga_map
        self.pixmap_cache = pixmap_cache
        self.editor = editor
        self.page_filter = page_filter
        # Retain Python subclasses for the lifetime of their C++ graphics items.
        self.editor._scene_items[ui_entry] = self

        self.current_state_title = editor._preview_states.get(ui_entry)

        x = get_float(ui_entry, "xOff", 0)
        y = get_float(ui_entry, "yOff", 0)
        self.setPos(x, y)

        state = self._current_state()
        self.width = get_float(state, "width", 0) if state is not None else 0
        self.height = get_float(state, "height", 0) if state is not None else 0

        self.setFlag(QGraphicsItem.ItemIsSelectable, True)
        drag_on = editor.drag_enabled and not editor.is_geometry_locked(ui_entry)
        self.setFlag(QGraphicsItem.ItemIsMovable, drag_on)
        self.setFlag(QGraphicsItem.ItemSendsGeometryChanges, True)
        self.setAcceptHoverEvents(True)

        self._resizing = False
        self._resize_start_pos = None
        self._resize_start_size = None
        self._drag_context = None
        self._resize_snapshot = None
        self._resize_state = None

        children = ui_entry.find("children")
        if children is not None:
            for child in children.findall("uiEntry"):
                if page_filter is not None:
                    ctitle = child.findtext("title") or ""
                    if is_page_title(ctitle) and ctitle != page_filter:
                        continue
                UiEntryItem(child, tga_map, pixmap_cache, editor,
                            self, page_filter)

    def boundingRect(self):
        return QRectF(0, 0, self.width, self.height)

    def shape(self):
        path = QPainterPath()
        path.addRect(QRectF(-2, -2, self.width + 4, self.height + 4))
        return path

    def paint(self, painter, option, widget):
        painter.setRenderHint(QPainter.RenderHint.Antialiasing, False)

        state = self._current_state()
        if state is not None:
            self._draw_tga_uses(painter, state)
            self._draw_text(painter, state)

        if self.isSelected():
            selection_pen = QPen(theme_color('accent'), 1.5)
            selection_pen.setCosmetic(True)
            painter.setPen(selection_pen)
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(0, 0, self.width, self.height)
            if not self.editor.is_geometry_locked(self.ui_entry):
                painter.setBrush(QBrush(theme_color('accent')))
                painter.setPen(Qt.NoPen)
                painter.drawRect(
                    self.width - self.HANDLE_SIZE,
                    self.height - self.HANDLE_SIZE,
                    self.HANDLE_SIZE,
                    self.HANDLE_SIZE,
                )
        else:
            painter.setPen(QPen(QColor(101, 112, 134, 65), 1, Qt.DotLine))
            painter.setBrush(Qt.NoBrush)
            painter.drawRect(0, 0, self.width, self.height)

    def _current_state(self):
        if self.current_state_title:
            s = get_first_state(self.ui_entry, self.current_state_title)
            if s is not None:
                return s
        return get_first_state(self.ui_entry)

    def _draw_tga_uses(self, painter, state):
        tga_uses = state.find("tgaUses")
        if tga_uses is None:
            return
        for tga_use in tga_uses.findall("tgaUse"):
            tga_id = tga_use.findtext("id")
            tga_def = self.tga_map.get(tga_id)
            if tga_def is None:
                continue
            path = (tga_def.findtext("path") or "").strip()
            if not path:
                continue
            x = get_float(tga_use, "xOff", 0)
            y = get_float(tga_use, "yOff", 0)
            w = get_float(tga_use, "width", 0)
            h = get_float(tga_use, "height", 0)
            r = get_int(tga_use, "redMultiply", 255)
            g = get_int(tga_use, "greenMultiply", 255)
            b = get_int(tga_use, "blueMultiply", 255)
            a = get_int(tga_use, "alphaMultiply", 255)
            pixmap = self.pixmap_cache.get_tinted(path, r, g, b, a)
            if pixmap is None or pixmap.isNull():
                painter.setBrush(QBrush(QColor(255, 0, 255, 60)))
                painter.setPen(QPen(QColor(255, 0, 255), 1, Qt.DashLine))
                painter.drawRect(x, y, w, h)
                continue
            painter.drawPixmap(QRectF(x, y, w, h), pixmap, QRectF(pixmap.rect()))

    def _draw_text(self, painter, state):
        text = state.findtext("stateText") or ""
        if not text.strip():
            return
        font_str = state.findtext("font") or "bardi_10, Normal"
        size = 12
        head = font_str.split(",")[0] if "," in font_str else font_str
        if "_" in head:
            try:
                size = int(head.split("_")[-1])
            except ValueError:
                size = 12
        font = QFont("Arial", size)
        color_value = state.findtext("textAlphaMultiply") or "-1"
        color = argb_to_qcolor(color_value, QColor(0, 0, 0, 255))
        painter.setFont(font)
        painter.setPen(QPen(color))
        painter.drawText(
            QRectF(0, 0, self.width, self.height),
            Qt.AlignCenter | Qt.TextWordWrap, text
        )

    # ---------- 鼠标事件 ----------
    def hoverMoveEvent(self, event):
        if self.editor.drag_enabled and not self.editor.is_geometry_locked(self.ui_entry):
            pos = event.pos()
            if (self.width - self.HANDLE_SIZE) <= pos.x() <= self.width and \
               (self.height - self.HANDLE_SIZE) <= pos.y() <= self.height:
                self.setCursor(Qt.SizeFDiagCursor)
            else:
                self.setCursor(Qt.ArrowCursor)
        else:
            self.setCursor(Qt.ArrowCursor)
        super().hoverMoveEvent(event)

    def mousePressEvent(self, event):
        drag_on = self.editor.drag_enabled and not self.editor.is_geometry_locked(self.ui_entry)
        pos = event.pos()
        handle = (self.width - self.HANDLE_SIZE <= pos.x() <= self.width and
                  self.height - self.HANDLE_SIZE <= pos.y() <= self.height)
        if event.button() == Qt.LeftButton and drag_on and self.isSelected() and handle:
            self._resizing = True
            self._resize_start_pos = self.mapFromScene(event.scenePos())
            self._resize_start_size = (self.width, self.height)
            self._resize_state = self._current_state()
            self._resize_snapshot = self.editor.begin_edit([self._resize_state], shallow=True)
            event.accept()
            return
        super().mousePressEvent(event)
        if event.button() == Qt.LeftButton and drag_on and self.isSelected():
            self._drag_context = self.editor.begin_drag(self, event.scenePos())

    def mouseMoveEvent(self, event):
        if not self.editor.drag_enabled or self.editor.is_geometry_locked(self.ui_entry):
            event.accept()
            return
        if self._resizing:
            delta = self.mapFromScene(event.scenePos()) - self._resize_start_pos
            self.prepareGeometryChange()
            self.width = max(1, self._resize_start_size[0] + delta.x())
            self.height = max(1, self._resize_start_size[1] + delta.y())
            self.update()
            event.accept()
            return
        if self._drag_context is not None:
            self.editor.move_drag(self._drag_context, event.scenePos())
            event.accept()
            return
        super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        self.editor.clear_snap_guides()
        if self._resizing:
            self._resizing = False
            self.prepareGeometryChange()
            self.width = max(1, int(round(self.width)))
            self.height = max(1, int(round(self.height)))
            self.update()
            # The actual XML state is captured at press time, independent of preview changes.
            if self._resize_state is not None:
                self._set_text_in(self._resize_state, 'width', str(int(round(self.width))))
                self._set_text_in(self._resize_state, 'height', str(int(round(self.height))))
            snapshot = self._resize_snapshot
            self._resize_snapshot = None
            self.editor.finish_edit(snapshot, '调整大小')
            event.accept()
            return
        if self._drag_context is not None:
            context = self._drag_context
            self._drag_context = None
            self.editor.end_drag(context)
        super().mouseReleaseEvent(event)

    def itemChange(self, change, value):
        if change == QGraphicsItem.ItemPositionHasChanged:
            self.update()
        return super().itemChange(change, value)

    # ---------- 写回 XML ----------
    def _write_pos_to_xml(self):
        pos = self.pos()
        self._set_text("xOff", str(int(round(pos.x()))))
        self._set_text("yOff", str(int(round(pos.y()))))

    def _write_size_to_xml(self):
        state = self._current_state()
        if state is None:
            return
        self._set_text_in(state, "width", str(int(round(self.width))))
        self._set_text_in(state, "height", str(int(round(self.height))))

    def _set_text(self, tag, value):
        elem = self.ui_entry.find(tag)
        if elem is None:
            elem = etree.SubElement(self.ui_entry, tag)
        elem.text = value

    def _set_text_in(self, parent, tag, value):
        elem = parent.find(tag)
        if elem is None:
            elem = etree.SubElement(parent, tag)
        elem.text = value

    def refresh_from_xml(self, recursive=True):
        x = get_float(self.ui_entry, "xOff", 0)
        y = get_float(self.ui_entry, "yOff", 0)
        self.setPos(x, y)
        state = self._current_state()
        self.prepareGeometryChange()
        self.width = get_float(state, "width", 0) if state is not None else 0
        self.height = get_float(state, "height", 0) if state is not None else 0
        self.update()
        if recursive:
            for child in self.childItems():
                if isinstance(child, UiEntryItem):
                    child.refresh_from_xml()

    def apply_state_title(self, title):
        self.current_state_title = title
        self.editor._preview_states[self.ui_entry] = title
        state = self._current_state()
        self.prepareGeometryChange()
        self.width = get_float(state, "width", 0) if state is not None else 0
        self.height = get_float(state, "height", 0) if state is not None else 0
        self.update()
        for child in self.childItems():
            if isinstance(child, UiEntryItem):
                child.apply_state_title(title)


# =========================================================
# 对齐辅助线管理器
# =========================================================
class SnapGuideManager:
    def __init__(self):
        self.guides = []
        self._pen = QPen(theme_color('guide'), 1, Qt.DashLine)
        self._pen.setCosmetic(True)

    def clear(self):
        self.guides.clear()

    def add(self, orientation, coord, start, end):
        if orientation == 'v':
            self.add_line(QPointF(coord, start), QPointF(coord, end))
        else:
            self.add_line(QPointF(start, coord), QPointF(end, coord))

    def add_line(self, start, end):
        self.guides.append((QPointF(start), QPointF(end)))

    def draw(self, painter, view):
        painter.setPen(self._pen)
        for start, end in self.guides:
            painter.drawLine(start, end)


# =========================================================
# 画布视图
# =========================================================
class CanvasView(QGraphicsView):
    item_selected = Signal(object)
    selection_count_changed = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setRenderHint(QPainter.RenderHint.Antialiasing, True)
        self.setDragMode(QGraphicsView.RubberBandDrag)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setMouseTracking(True)

        self.scene = QGraphicsScene(self)
        self.setScene(self.scene)
        self.setBackgroundBrush(QBrush(theme_color('canvas')))
        self.scene.selectionChanged.connect(self._on_selection_changed)

        self._show_grid = True
        self.snap_manager = SnapGuideManager()

    def drawBackground(self, painter, rect):
        super().drawBackground(painter, rect)
        if not self._show_grid:
            return
        grid = 20
        left = int(rect.left()) - (int(rect.left()) % grid)
        top = int(rect.top()) - (int(rect.top()) % grid)

        painter.setPen(QPen(theme_color('grid'), 0))
        lines = []
        x = left
        while x < rect.right():
            lines.append((QPointF(x, rect.top()), QPointF(x, rect.bottom())))
            x += grid
        y = top
        while y < rect.bottom():
            lines.append((QPointF(rect.left(), y), QPointF(rect.right(), y)))
            y += grid
        for a, b in lines:
            painter.drawLine(a, b)

        painter.setPen(QPen(theme_color('grid_major'), 0))
        big = grid * 5
        x = left - (left % big)
        while x < rect.right():
            painter.drawLine(QPointF(x, rect.top()), QPointF(x, rect.bottom()))
            x += big
        y = top - (top % big)
        while y < rect.bottom():
            painter.drawLine(QPointF(rect.left(), y), QPointF(rect.right(), y))
            y += big

    def drawForeground(self, painter, rect):
        super().drawForeground(painter, rect)
        self.snap_manager.draw(painter, self)

    def _on_selection_changed(self):
        items = [i for i in self.scene.selectedItems() if isinstance(i, UiEntryItem)]
        self.selection_count_changed.emit(len(items))
        if items:
            self.item_selected.emit(items[0])
        else:
            self.item_selected.emit(None)

    def selected_ui_items(self):
        return [i for i in self.scene.selectedItems() if isinstance(i, UiEntryItem)]

    def wheelEvent(self, event):
        if event.modifiers() & Qt.ControlModifier:
            factor = 1.1 if event.angleDelta().y() > 0 else 1 / 1.1
            self.scale(factor, factor)
        else:
            super().wheelEvent(event)

    def keyPressEvent(self, event):
        if event.key() == Qt.Key_0 and (event.modifiers() & Qt.ControlModifier):
            self.resetTransform()
        elif event.key() == Qt.Key_Escape:
            self.scene.clearSelection()
        else:
            super().keyPressEvent(event)

    def mousePressEvent(self, event):
        if event.button() == Qt.RightButton:
            item = self.itemAt(event.pos())
            if isinstance(item, UiEntryItem):
                if not item.isSelected():
                    self.scene.clearSelection()
                    item.setSelected(True)
                self._show_context_menu(item, event.globalPos())
                event.accept()
                return
            else:
                self._show_empty_menu(event.globalPos())
                event.accept()
                return
        super().mousePressEvent(event)

    def _show_context_menu(self, item, global_pos):
        menu = QMenu(self)
        act_add_child = menu.addAction("添加子节点")
        act_duplicate = menu.addAction("复制")
        act_delete = menu.addAction("删除")
        menu.addSeparator()
        act_add_sibling = menu.addAction("添加同级节点")
        action = menu.exec(global_pos)
        if action == act_add_child:
            self.window().add_child_to(item)
        elif action == act_duplicate:
            self.window().duplicate_item(item)
        elif action == act_delete:
            self.window().delete_item(item)
        elif action == act_add_sibling:
            self.window().add_sibling_to(item)

    def _show_empty_menu(self, global_pos):
        menu = QMenu(self)
        act_paste = menu.addAction("粘贴节点")
        act_paste.setEnabled(self.window().clipboard_ui_entry is not None)
        action = menu.exec(global_pos)
        if action == act_paste:
            self.window().paste_ui_entry_to_root()


# =========================================================
# 属性面板
# =========================================================
# Explicit format rules. Unknown tags are preserved and reported, never guessed.


class FieldDelegate(QStyledItemDelegate):
    def createEditor(self, parent, option, index):
        if index.column() != 1:
            return None
        element = index.siblingAtColumn(0).data(Qt.UserRole)
        attribute = index.siblingAtColumn(0).data(Qt.UserRole + 1)
        if element is None or not isinstance(element.tag, str):
            return None
        if attribute == 'num' and element.tag in COUNT_CHILD_TAGS:
            return None
        if attribute is None and (len(element) > 0 or element.tag in COUNT_CHILD_TAGS):
            return None
        rule = numeric_rule(element, attribute)
        if rule is not None:
            kind, low, high = rule
            if kind == 'float':
                editor = QDoubleSpinBox(parent)
                editor.setDecimals(6)
                editor.setRange(low, high)
                return editor
            if high <= 2147483647:
                editor = QSpinBox(parent)
                editor.setRange(low, high)
                return editor
        return super().createEditor(parent, option, index)

    def setEditorData(self, editor, index):
        if isinstance(editor, (QSpinBox, QDoubleSpinBox)):
            try:
                value = float(index.data() or '0')
                if not math.isfinite(value):
                    value = 0
                editor.setValue(int(value) if isinstance(editor, QSpinBox) else value)
            except (ValueError, OverflowError):
                editor.setValue(0)
        else:
            super().setEditorData(editor, index)

    def setModelData(self, editor, model, index):
        if isinstance(editor, QDoubleSpinBox):
            editor.interpretText()
            model.setData(index, format(editor.value(), '.6f').rstrip('0').rstrip('.') or '0')
        elif isinstance(editor, QSpinBox):
            editor.interpretText()
            model.setData(index, str(editor.value()))
        else:
            super().setModelData(editor, model, index)


class PropertiesPanel(QWidget):
    def __init__(self, editor, parent=None):
        super().__init__(parent)
        self.editor = editor
        self.current_item = None
        self.current_items = []
        self._building = False
        self._value_font = code_font()

        layout = QVBoxLayout(self)

        self.header_label = QLabel("未选中元素")
        self.header_label.setObjectName('SelectionHeader')
        layout.addWidget(self.header_label)

        quick_group = QGroupBox("快速编辑")
        form = QFormLayout(quick_group)

        self.title_edit = QLineEdit()
        self.x_edit = QSpinBox(); self.x_edit.setRange(-MAX_GEOMETRY, MAX_GEOMETRY)
        self.y_edit = QSpinBox(); self.y_edit.setRange(-MAX_GEOMETRY, MAX_GEOMETRY)
        self.w_edit = QSpinBox(); self.w_edit.setRange(0, MAX_GEOMETRY)
        self.h_edit = QSpinBox(); self.h_edit.setRange(0, MAX_GEOMETRY)
        self.state_combo = QComboBox()
        for spin in (self.x_edit, self.y_edit, self.w_edit, self.h_edit):
            spin.setKeyboardTracking(False)

        form.addRow("title", self.title_edit)
        form.addRow("xOff", self.x_edit)
        form.addRow("yOff", self.y_edit)
        form.addRow("width", self.w_edit)
        form.addRow("height", self.h_edit)
        form.addRow("预览 state", self.state_combo)
        layout.addWidget(quick_group)

        self.batch_label = QLabel("")
        self.batch_label.setObjectName('SelectionNote')
        layout.addWidget(self.batch_label)

        field_group = QGroupBox("全部字段")
        field_layout = QVBoxLayout(field_group)

        self.field_tree = QTreeWidget()
        self.field_tree.setColumnCount(2)
        self.field_tree.setItemDelegate(FieldDelegate(self.field_tree))
        self.field_tree.setEditTriggers(QAbstractItemView.EditKeyPressed)
        self.field_tree.setHeaderLabels(["字段", "值"])
        self.field_tree.setColumnWidth(0, 160)
        self.field_tree.itemChanged.connect(self._on_field_item_changed)
        self.field_tree.itemDoubleClicked.connect(self._on_field_double_clicked)
        self.field_tree.itemExpanded.connect(self._populate_field_item)
        self._field_root = None
        self._field_items = {}
        field_layout.addWidget(self.field_tree)

        field_btn_row = QHBoxLayout()
        add_field_btn = QPushButton("添加字段")
        del_field_btn = QPushButton("删除字段")
        add_field_btn.clicked.connect(self._add_field)
        del_field_btn.clicked.connect(self._del_field)
        field_btn_row.addWidget(add_field_btn)
        field_btn_row.addWidget(del_field_btn)
        field_btn_row.addStretch(1)
        field_layout.addLayout(field_btn_row)

        layout.addWidget(field_group, 1)

        self.x_edit.valueChanged.connect(self._on_pos_changed)
        self.y_edit.valueChanged.connect(self._on_pos_changed)
        self.w_edit.valueChanged.connect(self._on_size_changed)
        self.h_edit.valueChanged.connect(self._on_size_changed)
        self.state_combo.currentTextChanged.connect(self._on_state_changed)
        self.title_edit.editingFinished.connect(self._on_title_changed)

    def set_items(self, items):
        items = list(items or [])
        if len(items) <= 1:
            self.set_item(items[0] if items else None)
        else:
            self.current_items = items
            self._show_multi(items)

    def set_item(self, item):
        self._building = True
        self.current_item = item
        self.current_items = [item] if item is not None else []
        self.title_edit.setEnabled(item is not None)
        for spin in (self.x_edit, self.y_edit, self.w_edit, self.h_edit):
            spin.setEnabled(item is not None)
        self.state_combo.setEnabled(item is not None)
        self.field_tree.setEnabled(item is not None)
        if item is None:
            self.header_label.setText("未选中元素")
            self.batch_label.setText("")
            self.title_edit.clear()
            self.state_combo.clear()
            self.field_tree.clear()
            self._field_root = None
            self._field_items.clear()
            self.setEnabled(False)
            self._building = False
            return

        self.setEnabled(True)
        e = item.ui_entry
        self.header_label.setText(
            f"{e.findtext('title') or '?'}  (id={e.findtext('id') or '?'})"
        )
        self.batch_label.setText("")

        self.title_edit.setText(e.findtext("title") or "")
        pos = item.pos()
        self.x_edit.setValue(int(round(pos.x())))
        self.y_edit.setValue(int(round(pos.y())))
        self.w_edit.setValue(int(round(item.width)))
        self.h_edit.setValue(int(round(item.height)))

        self.state_combo.clear()
        titles = get_all_state_titles(e)
        if titles:
            self.state_combo.addItems(titles)
            if item.current_state_title and item.current_state_title in titles:
                self.state_combo.setCurrentText(item.current_state_title)
            else:
                self.state_combo.setCurrentIndex(0)

        self._build_field_tree(e)
        self._building = False

    def _show_multi(self, items):
        self._building = True
        for spin in (self.x_edit, self.y_edit, self.w_edit, self.h_edit):
            spin.setEnabled(True)
        self.current_item = None
        self.title_edit.setEnabled(False)
        self.state_combo.setEnabled(False)
        self.field_tree.setEnabled(False)
        self.setEnabled(True)
        self.header_label.setText(f"已选中 {len(items)} 个元素")
        self.batch_label.setText("批量模式：修改 xOff/yOff/width/height 会应用到所有选中元素")
        self.title_edit.clear()
        self.state_combo.clear()
        self.field_tree.clear()
        self._field_root = None
        self._field_items.clear()

        pos = items[0].pos()
        self.x_edit.setValue(int(round(pos.x())))
        self.y_edit.setValue(int(round(pos.y())))
        self.w_edit.setValue(int(round(items[0].width)))
        self.h_edit.setValue(int(round(items[0].height)))
        self._building = False

    def show_xml_element(self, element, caption):
        self._building = True
        try:
            self.current_item = None
            self.current_items = []
            self.setEnabled(True)
            self.header_label.setText(caption + ' · ' + str(element.tag))
            self.batch_label.setText('可编辑下方 XML 字段；定位不修改文档内容。')
            self.title_edit.clear()
            self.state_combo.clear()
            self.title_edit.setEnabled(False)
            self.state_combo.setEnabled(False)
            for spin in (self.x_edit, self.y_edit, self.w_edit, self.h_edit):
                spin.setEnabled(False)
            self.field_tree.setEnabled(True)
            self._build_field_tree(element)
        finally:
            self._building = False

    def _build_field_tree(self, element):
        previous = self._building
        self._building = True
        try:
            if self._field_root is element:
                # Keep materialized rows, expansion, selection and scroll position.
                for (node, attribute), item in self._field_items.items():
                    value = self._field_value(node) if attribute is None else node.get(attribute, '')
                    if item.text(1) != value:
                        item.setText(1, value)
                return
            self.field_tree.clear()
            self._field_items.clear()
            self._field_root = element
            for name, value in element.attrib.items():
                self._add_attribute_row(element, name, value, self.field_tree.invisibleRootItem())
            for child in element:
                self._add_xml_node_to_tree(child, self.field_tree.invisibleRootItem())
            for child in element:
                # Avoid listing an entire UI subtree just by selecting its parent.
                if child.tag != 'children' and len(child) <= 16:
                    self._field_items[(child, None)].setExpanded(True)
        finally:
            self._building = previous

    def _field_value(self, element):
        if isinstance(element.tag, str) and (len(element) or element.tag in COUNT_CHILD_TAGS):
            return f'({sum(isinstance(child.tag, str) for child in element)} 个子元素)'
        return element.text or ''

    def _add_attribute_row(self, element, name, value, parent):
        row = QTreeWidgetItem(['@' + name, value])
        row.setFont(1, self._value_font)
        row.setData(0, Qt.UserRole, element)
        row.setData(0, Qt.UserRole + 1, name)
        if not (name == 'num' and element.tag in COUNT_CHILD_TAGS):
            row.setFlags(row.flags() | Qt.ItemIsEditable)
        else:
            row.setToolTip(1, '数量由实际子节点自动计算')
        parent.addChild(row)
        self._field_items[(element, name)] = row

    def _populate_field_item(self, item):
        if item.data(0, Qt.UserRole + 2) is not False:
            return
        element = item.data(0, Qt.UserRole)
        previous = self._building
        self._building = True
        try:
            item.setData(0, Qt.UserRole + 2, True)
            for child in element:
                self._add_xml_node_to_tree(child, item)
        finally:
            self._building = previous

    def ensure_field_item(self, element, attribute=None):
        """Reveal only the ancestor path, also used by keyboard/editor integration."""
        if self._field_root is None:
            return None
        if element is not self._field_root:
            chain = []
            current = element
            while current is not None and current is not self._field_root:
                chain.append(current)
                current = current.getparent()
            if current is None:
                return None
            for node in reversed(chain):
                row = self._field_items.get((node, None))
                if row is None:
                    return None
                if node is not element or attribute is not None:
                    self._populate_field_item(row)
                    row.setExpanded(True)
        row = self._field_items.get((element, attribute))
        if row is not None:
            self.field_tree.scrollToItem(row)
        return row

    def _add_xml_node_to_tree(self, xml_elem, parent_item):
        tag = xml_elem.tag
        is_element = isinstance(tag, str)
        label = tag if is_element else ('#comment' if isinstance(xml_elem, etree._Comment) else '#processing-instruction')
        item = QTreeWidgetItem([label, self._field_value(xml_elem)])
        item.setFont(1, self._value_font)
        item.setData(0, Qt.UserRole, xml_elem)
        if is_element and len(xml_elem) == 0 and tag not in COUNT_CHILD_TAGS:
            item.setFlags(item.flags() | Qt.ItemIsEditable)
        parent_item.addChild(item)
        self._field_items[(xml_elem, None)] = item
        for name, value in xml_elem.attrib.items():
            self._add_attribute_row(xml_elem, name, value, item)
        if len(xml_elem):
            item.setData(0, Qt.UserRole + 2, False)
            item.setChildIndicatorPolicy(QTreeWidgetItem.ShowIndicator)

    def _on_field_item_changed(self, item, column):
        if self._building or column != 1:
            return
        xml_elem = item.data(0, Qt.UserRole)
        attribute = item.data(0, Qt.UserRole + 1)
        if xml_elem is None or not isinstance(xml_elem.tag, str):
            return
        if not self.editor.edit_xml_value(xml_elem, item.text(1), attribute, defer=True):
            with QSignalBlocker(self.field_tree):
                item.setText(1, (xml_elem.get(attribute, '') if attribute is not None else xml_elem.text or ''))

    def _on_field_double_clicked(self, item, column):
        if column != 1:
            return
        xml_elem = item.data(0, Qt.UserRole)
        attribute = item.data(0, Qt.UserRole + 1)
        if xml_elem is None or not isinstance(xml_elem.tag, str):
            return
        if attribute is not None or numeric_rule(xml_elem) is not None or identifier_kind(xml_elem) or reference_kind(xml_elem):
            self.field_tree.editItem(item, 1)
            return
        if len(xml_elem) > 0 or xml_elem.tag in COUNT_CHILD_TAGS:
            return
        text, ok = self._edit_long_text(xml_elem.tag, xml_elem.text or '')
        if ok:
            self.editor.edit_xml_value(xml_elem, text, defer=True)

    def _edit_long_text(self, title, text):
        dlg = QDialog(self)
        dlg.setWindowTitle(f"编辑 {title}")
        dlg.resize(600, 400)
        layout = QVBoxLayout(dlg)
        editor = QTextEdit()
        editor.setPlainText(text)
        layout.addWidget(editor)
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.accepted.connect(dlg.accept)
        buttons.rejected.connect(dlg.reject)
        layout.addWidget(buttons)
        result = dlg.exec()
        return editor.toPlainText(), result == QDialog.Accepted

    def _add_field(self):
        if self.current_item is None:
            return
        name, ok = QInputDialog.getText(self, '添加字段', '字段名（@名称表示属性）:')
        if not ok or not name.strip():
            return
        name = name.strip()
        entry = self.current_item.ui_entry
        snapshot = self.editor.begin_edit([entry])
        try:
            if name.startswith('@'):
                attribute = name[1:]
                if attribute in entry.attrib:
                    raise ValueError('该属性已存在')
                entry.set(attribute, '')
            else:
                if entry.find(name) is not None:
                    raise ValueError('该字段已存在，请编辑现有字段')
                element = etree.SubElement(entry, name)
                if name in COUNT_CHILD_TAGS:
                    sync_count(element)
                elif name == 'id':
                    element.text = allocate_id(self.editor.xml_root)
                elif numeric_rule(element) is not None:
                    element.text = '0'
        except (ValueError, SyntaxError) as error:
            # Invalid names are rejected by lxml before an element/attribute is added.
            QMessageBox.warning(self, '无法添加字段', str(error))
            return
        self.editor.finish_edit(snapshot, '添加字段', rebuild=True)

    def _del_field(self):
        item = self.field_tree.currentItem()
        if item is None or self.current_item is None:
            return
        xml_elem = item.data(0, Qt.UserRole)
        attribute = item.data(0, Qt.UserRole + 1)
        if xml_elem is None or not isinstance(xml_elem.tag, str):
            return
        if attribute is not None:
            if attribute == 'num' and xml_elem.tag in COUNT_CHILD_TAGS:
                QMessageBox.warning(self, '无法删除', '数量属性由实际子节点自动维护')
                return
            snapshot = self.editor.begin_edit([xml_elem])
            xml_elem.attrib.pop(attribute, None)
        else:
            parent = xml_elem.getparent()
            if parent is None:
                return
            snapshot = self.editor.begin_edit([parent])
            parent.remove(xml_elem)
        self.editor.finish_edit(snapshot, '删除字段', rebuild=True)

    def flush_pending_edits(self):
        self.editor._pending_edit_valid = True
        focus = QApplication.focusWidget()
        if focus is not None and self.field_tree.isAncestorOf(focus) and focus is not self.field_tree:
            # The delegate commits the active cell synchronously, before serialization.
            if isinstance(focus, QLineEdit) and isinstance(focus.parentWidget(), (QSpinBox, QDoubleSpinBox)):
                focus = focus.parentWidget()
            delegate = self.field_tree.itemDelegate()
            delegate.commitData.emit(focus)
            delegate.closeEditor.emit(focus, QAbstractItemDelegate.NoHint)
        for spin in (self.x_edit, self.y_edit, self.w_edit, self.h_edit):
            spin.interpretText()
        if self.current_item is not None and self.title_edit.isModified():
            self._on_title_changed()
        return self.editor._pending_edit_valid

    def _on_pos_changed(self):
        if self._building or not self.current_items:
            return
        axis = 'x' if self.sender() is self.x_edit else 'y'
        value = self.x_edit.value() if axis == 'x' else self.y_edit.value()
        items = list(self.current_items)
        snapshot = self.editor.begin_edit([it.ui_entry for it in items], shallow=True)
        for it in items:
            if axis == 'x':
                it.setX(value)
            else:
                it.setY(value)
            it._write_pos_to_xml()
        self.editor.finish_edit(snapshot, '修改位置' if len(items) == 1 else '批量修改位置')

    def _on_size_changed(self):
        if self._building or not self.current_items:
            return
        axis = 'width' if self.sender() is self.w_edit else 'height'
        value = self.w_edit.value() if axis == 'width' else self.h_edit.value()
        items = list(self.current_items)
        snapshot = self.editor.begin_edit([it._current_state() for it in items], shallow=True)
        for it in items:
            state = it._current_state()
            if state is not None:
                it._set_text_in(state, axis, str(value))
        self.editor.finish_edit(snapshot, '修改尺寸' if len(items) == 1 else '批量修改尺寸')

    def _on_title_changed(self):
        if self._building or self.current_item is None:
            return
        entry = self.current_item.ui_entry
        title = entry.find('title')
        if title is None:
            snapshot = self.editor.begin_edit([entry])
            etree.SubElement(entry, 'title').text = self.title_edit.text()
            self.editor.finish_edit(snapshot, '修改节点名称', rebuild=True)
        else:
            self.editor.edit_xml_value(title, self.title_edit.text())

    def _on_state_changed(self, title):
        if self._building or self.current_item is None or not title:
            return
        self.current_item.apply_state_title(title)
        state = self.current_item._current_state()
        if state is not None:
            self._building = True
            self.w_edit.setValue(int(round(self.current_item.width)))
            self.h_edit.setValue(int(round(self.current_item.height)))
            self._building = False

    def refresh_pos_size(self):
        if self.current_item is None:
            return
        self._building = True
        pos = self.current_item.pos()
        self.x_edit.setValue(int(round(pos.x())))
        self.y_edit.setValue(int(round(pos.y())))
        self.w_edit.setValue(int(round(self.current_item.width)))
        self.h_edit.setValue(int(round(self.current_item.height)))
        self._building = False

    def refresh_field_tree(self):
        if self.current_item is not None:
            self._build_field_tree(self.current_item.ui_entry)


# =========================================================
# 状态机可视化
# =========================================================
class StateMachineView(QGraphicsView):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setRenderHint(QPainter.RenderHint.Antialiasing, True)
        self.scene = QGraphicsScene()
        self.setScene(self.scene)
        self.setBackgroundBrush(QBrush(theme_color('canvas')))

    def load_states(self, ui_entry):
        self.scene.clear()
        if ui_entry is None:
            return
        states_elem = ui_entry.find("states")
        if states_elem is None:
            return
        states = states_elem.findall("state")

        cols = 3
        node_w = 180
        node_h = 90
        margin_x = 40
        margin_y = 40

        state_nodes = {}
        state_ids = {}
        for idx, state in enumerate(states):
            row = idx // cols
            col = idx % cols
            x = margin_x + col * (node_w + margin_x)
            y = margin_y + row * (node_h + margin_y)

            title = state.findtext("title") or "?"
            state_id = state.findtext("id") or "?"
            state_ids[state_id] = state

            rect = self.scene.addRect(
                QRectF(0, 0, node_w, node_h),
                QPen(theme_color('border'), 1.5),
                QBrush(theme_color('surface'))
            )
            rect.setPos(x, y)

            text = f"[{state_id}] {title}"
            txt_item = self.scene.addSimpleText(text, ui_font(10, bold=True))
            txt_item.setPos(x + 8, y + 8)
            txt_item.setBrush(QBrush(theme_color('text')))

            w = state.findtext("width") or "0"
            h = state.findtext("height") or "0"
            size_item = self.scene.addSimpleText(f"{w} x {h}", ui_font(9))
            size_item.setPos(x + 8, y + 30)
            size_item.setBrush(QBrush(theme_color('muted')))

            st = state.findtext("stateText") or ""
            if st:
                short = st if len(st) < 20 else st[:18] + "..."
                st_item = self.scene.addSimpleText(short, ui_font(8))
                st_item.setPos(x + 8, y + 50)
                st_item.setBrush(QBrush(theme_color('muted')))

            state_nodes[state_id] = (x, y, node_w, node_h)

        for state in states:
            source_id = state.findtext("id") or ""
            transitions_elem = state.find("transitions")
            if transitions_elem is None:
                continue
            for trans in transitions_elem.findall("transition"):
                target_id = trans.findtext("stateIDRef") or ""
                ttype = trans.findtext("type") or ""
                if target_id not in state_nodes or source_id not in state_nodes:
                    continue
                sx, sy, sw, sh = state_nodes[source_id]
                tx, ty, tw, th = state_nodes[target_id]
                src_center = QPointF(sx + sw / 2, sy + sh)
                dst_center = QPointF(tx + tw / 2, ty)
                self._draw_arrow(src_center, dst_center, f"type={ttype}")

    def _draw_arrow(self, src, dst, label):
        pen = QPen(theme_color('accent'), 1.2)
        self.scene.addLine(src.x(), src.y(), dst.x(), dst.y(), pen)

        dx = dst.x() - src.x()
        dy = dst.y() - src.y()
        length = (dx * dx + dy * dy) ** 0.5
        if length < 1:
            return
        ux, uy = dx / length, dy / length
        head = 8
        left = QPointF(dst.x() - ux * head - uy * head * 0.5,
                       dst.y() - uy * head + ux * head * 0.5)
        right = QPointF(dst.x() - ux * head + uy * head * 0.5,
                        dst.y() - uy * head - ux * head * 0.5)
        poly = QPolygonF([dst, left, right])
        self.scene.addPolygon(poly, QPen(theme_color('accent')), QBrush(theme_color('accent')))

        mid = QPointF((src.x() + dst.x()) / 2, (src.y() + dst.y()) / 2)
        txt = self.scene.addSimpleText(label, ui_font(8))
        txt.setPos(mid.x() + 4, mid.y() + 2)
        txt.setBrush(QBrush(theme_color('accent')))


class StateMachineDialog(QDialog):
    def __init__(self, ui_entry, parent=None):
        super().__init__(parent)
        self.setWindowTitle("状态机可视化")
        self.resize(1000, 700)

        layout = QVBoxLayout(self)

        title = ui_entry.findtext("title") if ui_entry is not None else "?"
        layout.addWidget(QLabel(f"元素: {title}"))

        self.view = StateMachineView()
        layout.addWidget(self.view, 1)

        buttons = QDialogButtonBox(QDialogButtonBox.Close)
        buttons.rejected.connect(self.reject)
        buttons.accepted.connect(self.accept)
        layout.addWidget(buttons)

        self.view.load_states(ui_entry)
        rect = self.view.scene.itemsBoundingRect()
        self.view.scene.setSceneRect(rect.adjusted(-40, -40, 40, 40))


# =========================================================
# 资源对话框
# =========================================================
class ResourceDialog(QDialog):
    def __init__(self, resolver, parent=None):
        super().__init__(parent)
        self.setWindowTitle("资源根目录设置")
        self.resize(600, 400)
        self.resolver = resolver

        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("TGA 资源根目录列表（从上到下依次尝试）："))

        self.list_widget = QListWidget()
        for r in resolver.roots:
            self.list_widget.addItem(r)
        layout.addWidget(self.list_widget)

        btn_row = QHBoxLayout()
        add_btn = QPushButton("添加目录")
        remove_btn = QPushButton("移除选中")
        up_btn = QPushButton("上移")
        down_btn = QPushButton("下移")
        btn_row.addWidget(add_btn); btn_row.addWidget(remove_btn)
        btn_row.addWidget(up_btn); btn_row.addWidget(down_btn)
        btn_row.addStretch(1)
        layout.addLayout(btn_row)

        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        add_btn.clicked.connect(self._add_dir)
        remove_btn.clicked.connect(self._remove_dir)
        up_btn.clicked.connect(self._move_up)
        down_btn.clicked.connect(self._move_down)

    def _add_dir(self):
        d = QFileDialog.getExistingDirectory(self, "选择资源根目录")
        if d:
            self.list_widget.addItem(d)

    def _remove_dir(self):
        row = self.list_widget.currentRow()
        if row >= 0:
            self.list_widget.takeItem(row)

    def _move_up(self):
        row = self.list_widget.currentRow()
        if row > 0:
            item = self.list_widget.takeItem(row)
            self.list_widget.insertItem(row - 1, item)
            self.list_widget.setCurrentRow(row - 1)

    def _move_down(self):
        row = self.list_widget.currentRow()
        if 0 <= row < self.list_widget.count() - 1:
            item = self.list_widget.takeItem(row)
            self.list_widget.insertItem(row + 1, item)
            self.list_widget.setCurrentRow(row + 1)

    def result_roots(self):
        return [self.list_widget.item(i).text() for i in range(self.list_widget.count())]


# =========================================================
# 主窗口
# =========================================================
class MainWindow(RecoveryController, EditingController, AssetsController, NavigationController, QMainWindow):
    def __init__(self):
        super().__init__()
        apply_light_theme(QApplication.instance())
        self.setWindowIcon(theme_icon('state', 'accent'))
        self.setWindowTitle("Tensho Config Panel 编辑器")
        self.resize(1700, 950)

        self.settings = QSettings("TenshoEditor", "TenshoEditor")

        self.xml_path = None
        self.xml_tree = None
        self.xml_root = None
        self.tga_map = {}

        self.resolver = ResourceResolver()
        self.pixmap_cache = PixmapCache(self.resolver)
        self.command_stack = CommandStack()
        self.clipboard_ui_entry = None
        self._preview_states = {}
        self._scene_items = {}
        self._tree_items = {}
        self._index = DocumentIndex(None)
        self._validation_dirty = True
        self._pending_refresh = None
        self._document_generation = 0
        self._saved_fingerprint = None
        self._xml_declaration = False
        self._pending_edit_valid = True
        self._document_issues = []

        # 当前显示的 page 标题（None = 显示全部，会重叠）
        self.current_page_title = None
        # 是否允许鼠标拖拽组件（False = 仅选中，不响应拖动/缩放）
        self.drag_enabled = True

        self.tree_widget = QTreeWidget()
        self.tree_widget.setObjectName('HierarchyTree')
        self.tree_widget.setHeaderLabels(['UI 层级', 'ID', '锁定', '隐藏'])
        self.tree_widget.setColumnWidth(0, 165)
        self.tree_widget.setColumnWidth(1, 75)
        self.tree_widget.setColumnWidth(2, 55)
        self.tree_widget.setColumnWidth(3, 55)
        self.tree_widget.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.tree_widget.itemSelectionChanged.connect(self._on_tree_selection)

        self.canvas = CanvasView()
        self.canvas.selection_count_changed.connect(self._on_selection_count_changed)

        self.props = PropertiesPanel(self)
        self.props.setObjectName('InspectorPanel')
        self.props.setAttribute(Qt.WA_StyledBackground, True)

        splitter = QSplitter(Qt.Horizontal)
        splitter.setObjectName('EditorSurface')
        splitter.setContentsMargins(10, 10, 10, 10)
        hierarchy = QWidget()
        hierarchy.setObjectName('HierarchyPanel')
        hierarchy_layout = QVBoxLayout(hierarchy)
        hierarchy_layout.setContentsMargins(0, 0, 0, 0)
        hierarchy_layout.setSpacing(0)
        heading = QLabel('UI 层级')
        heading.setObjectName('PanelHeading')
        hierarchy_layout.addWidget(heading)
        hierarchy_layout.addWidget(self.tree_widget)
        splitter.addWidget(hierarchy)
        center = QWidget()
        cl = QVBoxLayout(center)
        cl.setContentsMargins(0, 0, 0, 0)
        caption = QLabel('画布预览')
        caption.setObjectName('CanvasHeading')
        cl.addWidget(caption)
        cl.addWidget(self.canvas)
        splitter.addWidget(center)
        splitter.addWidget(self.props)
        splitter.setSizes([350, 900, 420])
        self.setCentralWidget(splitter)

        self._create_toolbar()
        self._init_navigation()
        self._init_assets()
        self._init_editing(StateMachineView)
        self._init_recovery()
        self.update_undo_actions()
        self.setStatusBar(QStatusBar())
        self._current_scene_item = None

        saved_roots = self.settings.value("resource_roots", [], type=list)
        if saved_roots:
            self.resolver.set_roots(saved_roots)

    # ---------- 菜单栏 + 工具栏 ----------
    def _create_toolbar(self):
        # ============================================
        # 顶部菜单栏：文件
        # ============================================
        menubar = self.menuBar()
        file_menu = menubar.addMenu("文件")

        open_action = QAction("打开 XML", self)
        open_action.setIcon(theme_icon('open'))
        open_action.setShortcut(QKeySequence.Open)
        open_action.triggered.connect(self.open_xml)
        file_menu.addAction(open_action)

        save_action = QAction("保存 XML", self)
        save_action.setIcon(theme_icon('save', 'accent'))
        save_action.setShortcut(QKeySequence.Save)
        save_action.triggered.connect(self.save_xml)
        file_menu.addAction(save_action)

        save_as_action = QAction("另存为...", self)
        save_as_action.setIcon(theme_icon('save'))
        save_as_action.setShortcut(QKeySequence.SaveAs)
        save_as_action.triggered.connect(self.save_xml_as)
        file_menu.addAction(save_as_action)

        file_menu.addSeparator()

        close_action = QAction("关闭当前 XML", self)
        close_action.triggered.connect(self.close_xml)
        file_menu.addAction(close_action)

        self.check_action = QAction("文档检查", self)
        self.check_action.triggered.connect(self.show_document_check)
        menubar.addAction(self.check_action)
        resource_check = QAction('资源检查', self)
        resource_check.triggered.connect(self.show_resource_check)
        menubar.addAction(resource_check)

        # ============================================
        # 工具栏：只保留工具类按钮
        # ============================================
        tb = QToolBar("主工具栏")
        tb.setIconSize(QSize(18, 18))
        tb.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.addToolBar(tb)

        refresh_action = QAction("刷新画布", self)
        refresh_action.setIcon(theme_icon('refresh'))
        refresh_action.triggered.connect(self.rebuild_scene)
        tb.addAction(refresh_action)

        resource_action = QAction("资源目录", self)
        resource_action.setIcon(theme_icon('folder'))
        resource_action.triggered.connect(self.open_resource_dialog)
        tb.addAction(resource_action)

        tb.addSeparator()

        self.grid_action = QAction("网格", self, checkable=True)
        self.grid_action.setIcon(theme_icon('grid'))
        self.grid_action.setChecked(True)
        self.grid_action.toggled.connect(self._toggle_grid)
        tb.addAction(self.grid_action)

        tb.addSeparator()

        # ---- 拖拽模式开关 ----
        self.drag_action = QAction("可拖拽", self, checkable=True)
        self.drag_action.setIcon(theme_icon('move'))
        self.drag_action.setChecked(True)
        self.drag_action.setToolTip(
            "勾选：可用鼠标拖动/缩放组件\n"
            "取消勾选：仅能选中（防止误拖）"
        )
        self.drag_action.toggled.connect(self._toggle_drag)
        tb.addAction(self.drag_action)

        tb.addSeparator()

        # ---- 页面选择器 ----
        tb.addWidget(QLabel("  页面: "))
        self.page_combo = QComboBox()
        self.page_combo.setMinimumWidth(160)
        self.page_combo.currentTextChanged.connect(self._on_page_changed)
        tb.addWidget(self.page_combo)

        tb.addSeparator()

        self.undo_action = undo_action = QAction("撤销", self)
        undo_action.setIcon(theme_icon('undo'))
        undo_action.setShortcut(QKeySequence.Undo)
        undo_action.triggered.connect(self.undo)
        tb.addAction(undo_action)

        self.redo_action = redo_action = QAction("重做", self)
        redo_action.setIcon(theme_icon('redo'))
        redo_action.setShortcut(QKeySequence.Redo)
        redo_action.triggered.connect(self.redo)
        tb.addAction(redo_action)

        tb.addSeparator()

        self.align_button = QToolButton()
        self.align_button.setText("对齐工具")
        self.align_button.setIcon(theme_icon('align'))
        self.align_button.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        self.align_button.setPopupMode(QToolButton.InstantPopup)
        menu = QMenu(self.align_button)

        menu.addAction("左对齐", lambda: self.align_selected("left"))
        menu.addAction("水平居中", lambda: self.align_selected("hcenter"))
        menu.addAction("右对齐", lambda: self.align_selected("right"))
        menu.addSeparator()
        menu.addAction("顶对齐", lambda: self.align_selected("top"))
        menu.addAction("垂直居中", lambda: self.align_selected("vcenter"))
        menu.addAction("底对齐", lambda: self.align_selected("bottom"))
        menu.addSeparator()
        menu.addAction("水平等间距", lambda: self.align_selected("hdistribute"))
        menu.addAction("垂直等间距", lambda: self.align_selected("vdistribute"))

        self.align_button.setMenu(menu)
        tb.addWidget(self.align_button)

        state_action = QAction("状态机", self)
        state_action.setIcon(theme_icon('state'))
        state_action.triggered.connect(self.show_state_machine)
        tb.addAction(state_action)

    def _toggle_grid(self, checked):
        self.canvas._show_grid = checked
        self.canvas.viewport().update()

    def _toggle_drag(self, checked):
        self.drag_enabled = checked
        self.drag_action.setText("可拖拽" if checked else "仅选中")
        for item in self.canvas.scene.items():
            if isinstance(item, UiEntryItem):
                item.setFlag(QGraphicsItem.ItemIsMovable, checked and not self.is_geometry_locked(item.ui_entry))
                item.setCursor(Qt.ArrowCursor)
                item.update()
        self.statusBar().showMessage(
            "拖拽模式：可拖动组件" if checked else "拖拽模式：仅选中（不可拖动）"
        )

    # ---------- 资源对话框 ----------
    def open_resource_dialog(self):
        dlg = ResourceDialog(self.resolver, self)
        if dlg.exec() == QDialog.Accepted:
            roots = dlg.result_roots()
            self.resolver.set_roots(roots)
            self.pixmap_cache.clear()
            self.settings.setValue("resource_roots", roots)
            self.rebuild_scene()

    # ---------- 页面管理 ----------
    def _find_panel_entry(self):
        if self._index.root is not self.xml_root:
            self._index = DocumentIndex(self.xml_root)
        return self._index.panel

    def refresh_page_list(self):
        with QSignalBlocker(self.page_combo):
            self.page_combo.clear()
            panel = self._find_panel_entry()
            scope = panel if panel is not None else self.xml_root
            pages = list(dict.fromkeys(entry.findtext('title') for entry in scope.iter('uiEntry')
                                      if is_page_title(entry.findtext('title')))) if scope is not None else []
            if pages:
                self.page_combo.addItems(pages)
                self.page_combo.addItem('(全部)')
                if self._show_all_pages:
                    self.current_page_title = None
                elif self.current_page_title not in pages:
                    self.current_page_title = pages[0]
                self.page_combo.setCurrentText(self.current_page_title or '(全部)')
            else:
                self.current_page_title = None
                self.page_combo.addItem('(全部)')

    def _on_page_changed(self, title):
        if not self.props.flush_pending_edits():
            with QSignalBlocker(self.page_combo):
                self.page_combo.setCurrentText(self.current_page_title or '(全部)')
            return
        self.cancel_active_gesture()
        self._show_all_pages = not title or title == '(全部)'
        self.current_page_title = None if self._show_all_pages else title
        self.canvas.scene.clearSelection()
        self._current_scene_item = None
        self.props.set_items([])
        self.build_tree()
        self.rebuild_scene(selection=[])
        self.statusBar().showMessage(f'当前页面: {title}')

    # ---------- 打开 / 保存 / 关闭 ----------
    def open_xml(self):
        path, _ = QFileDialog.getOpenFileName(self, '选择 UI XML', '', 'XML 文件 (*.xml)')
        if path:
            return self._load_xml(path)
        return False

    def _load_xml(self, path):
        # Parse a staged document first: a bad file never discards the current edits.
        try:
            with open(path, 'rb') as stream:
                raw = stream.read()
            parser = etree.XMLParser(remove_blank_text=False, strip_cdata=False,
                                     resolve_entities=False, load_dtd=False, no_network=True)
            tree = etree.parse(io.BytesIO(raw), parser, base_url=os.path.abspath(path))
        except (OSError, etree.Error, ValueError) as error:
            QMessageBox.critical(self, '解析失败', str(error))
            return False
        if not self.maybe_save_changes():
            return False
        return self._activate_document(tree, path, raw)

    def _activate_document(self, tree, path, raw, baseline=None):
        self.cancel_active_gesture()
        self._document_generation += 1
        self._pending_refresh = None
        self._validation_dirty = True
        self._store_view_state()
        self._reset_navigation()
        self._show_all_pages = False
        self._preview_states.clear()
        self.xml_path = os.fspath(path) if path else None
        self.xml_tree = tree
        self.xml_root = tree.getroot()
        if baseline is None:
            self._restore_view_state()
        else:
            self._restore_recovered_view_state(baseline)
        self._xml_declaration = raw.lstrip(b'\xef\xbb\xbf \t\r\n').startswith(b'<?xml')
        self._saved_fingerprint = self.document_fingerprint()
        self._checkpoint_loaded(raw, baseline)
        self.pixmap_cache.clear()
        self.command_stack.clear()
        self.tga_map.clear()
        for tga in self.xml_root.iter('tga'):
            tid = tga.findtext('id')
            if tid:
                self.tga_map[tid] = tga
        auto_roots = [os.path.dirname(os.path.abspath(path))] if path else []
        for extra in ('ui', 'UI'):
            sub = os.path.join(auto_roots[0], extra) if auto_roots else ''
            if os.path.isdir(sub):
                auto_roots.append(sub)
        existing = self.settings.value('resource_roots', [], type=list)
        self.resolver.set_roots(list(dict.fromkeys(auto_roots + list(existing))))
        self.current_page_title = None
        self.refresh_page_list()
        self.build_tree()
        self.rebuild_scene(selection=[])
        self.update_undo_actions()
        self.statusBar().showMessage(f'已加载: {path}')
        return True

    def save_xml(self):
        if self.xml_tree is None:
            return False
        if self.xml_path is None:
            return self.save_xml_as()
        return self._do_save(self.xml_path, review=True)

    def save_xml_as(self):
        if self.xml_tree is None:
            return False
        path, _ = QFileDialog.getSaveFileName(
            self, '另存为', self.xml_path or 'tensho_config_panel.xml', 'XML 文件 (*.xml)')
        if not path:
            return False
        if not os.path.splitext(path)[1]:
            path += '.xml'
        return self._do_save(path, review=True)

    def _do_save(self, path, review=False):
        if self.xml_tree is None or not self.props.flush_pending_edits():
            return False
        self.cancel_active_gesture()
        snapshot = self.begin_edit([self.xml_root])
        for element in self.xml_root.iter():
            sync_count(element)
        if not self.finish_edit(snapshot, '同步数量字段', rebuild=True):
            return False
        issues = inspect_document(self.xml_root)
        errors = [issue for issue in issues if issue[3] == 'error']
        if errors:
            QMessageBox.warning(self, '无法保存：请先修复文档错误', format_issues(errors))
            return False
        writer = None
        previous_path = self.xml_path
        try:
            payload = serialize_document(self.xml_tree, self._xml_declaration)
            if review and not self._review_save(path, payload):
                return False
            writer = QSaveFile(os.fspath(path))
            writer.setDirectWriteFallback(False)
            if not writer.open(QIODevice.WriteOnly):
                raise OSError(writer.errorString())
            if writer.write(payload) != len(payload):
                raise OSError(writer.errorString() or '写入的字节数不足')
            if not writer.commit():
                raise OSError(writer.errorString() or '无法提交临时文件')
        except (OSError, ValueError, etree.Error) as error:
            if writer is not None:
                writer.cancelWriting()
            QMessageBox.critical(self, '保存失败', str(error))
            return False
        self.xml_path = os.fspath(path)
        self.view_state.remember_saved_ids(self.xml_root)
        self._store_view_state()
        self._saved_fingerprint = self.document_fingerprint()
        self._checkpoint_saved(payload, previous_path)
        self.update_undo_actions()
        warnings = sum(issue[3] == 'warning' for issue in issues)
        suffix = f'（{warnings} 项待核对，可查看文档检查）' if warnings else ''
        self.statusBar().showMessage(f'已保存: {path}{suffix}')
        return True

    def close_xml(self):
        if self.xml_tree is None:
            return True
        if not self.maybe_save_changes():
            return False
        self.cancel_active_gesture()
        self._document_generation += 1
        self._pending_refresh = None
        self._validation_dirty = True
        self._store_view_state()
        self._reset_navigation()
        self.view_state.restore(None, '')
        self._show_all_pages = False
        self._preview_states.clear()
        self.xml_path = None
        self.xml_tree = None
        self.xml_root = None
        self._baseline = None
        self._base_disk_hash = None
        self.recovery_timer.stop()
        self._saved_fingerprint = None
        self._xml_declaration = False
        self.tga_map.clear()
        self.pixmap_cache.clear()
        self.command_stack.clear()
        self.props.set_items([])
        self._current_scene_item = None
        with QSignalBlocker(self.canvas.scene), QSignalBlocker(self.tree_widget):
            self.canvas.scene.clear()
            self._scene_items.clear()
            self.tree_widget.clear()
            self._tree_items.clear()
        self.current_page_title = None
        self.refresh_page_list()
        self.update_undo_actions()
        self.statusBar().showMessage('已关闭当前 XML')
        return True

    def closeEvent(self, event):
        if self.maybe_save_changes():
            self._store_view_state()
            self.settings.sync()
            self.cancel_active_gesture()
            self.recovery_timer.stop()
            event.accept()
        else:
            event.ignore()

    def document_fingerprint(self):
        if self.xml_tree is None:
            return None
        return hashlib.sha256(etree.tostring(self.xml_tree, encoding='utf-8')).digest()

    def is_modified(self):
        return self.xml_tree is not None and self.document_fingerprint() != self._saved_fingerprint

    def update_document_state(self):
        name = os.path.basename(self.xml_path) if self.xml_path else '未命名'
        self.setWindowTitle(f'{name}[*] - Tensho Config Panel 编辑器')
        self.setWindowModified(self.is_modified())
        if self._validation_dirty:
            self._document_issues = inspect_document(self.xml_root)
            self._validation_dirty = False
        errors = sum(issue[3] == 'error' for issue in self._document_issues)
        warnings = sum(issue[3] == 'warning' for issue in self._document_issues)
        self.check_action.setText(f'文档检查（错误 {errors} / 待核对 {warnings}）')

    def maybe_save_changes(self):
        if not self.props.flush_pending_edits():
            return False
        if not self.is_modified():
            self._retire_recovery()
            return True
        choice = QMessageBox.question(
            self, '保存修改', '当前 XML 有未保存的修改，是否保存？',
            QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel, QMessageBox.Save)
        if choice == QMessageBox.Save:
            return self.save_xml()
        if choice == QMessageBox.Discard:
            self._retire_recovery()
            return True
        return False

    def show_document_check(self):
        if not self.props.flush_pending_edits():
            return None
        issues = inspect_document(self.xml_root)
        rows = [('错误' if issue[3] == 'error' else '待核对', issue[2], self._issue_target(issue)) for issue in issues]
        return self._show_navigation_report('文档检查',
            format_issues(issues, len(issues)) if issues else '未发现已知格式错误。', rows)

    def show_resource_check(self):
        if not self.props.flush_pending_edits():
            return None
        self.pixmap_cache.clear()
        paths = {}
        if self.xml_root is not None:
            for texture in self.xml_root.iter('tga'):
                path = (texture.findtext('path') or '').strip()
                paths.setdefault(path, []).append(texture)
        failures, rows = [], []
        for path, definitions in paths.items():
            if not path:
                message = '空路径：贴图定义缺少有效 path'
            elif self.pixmap_cache.get_raw(path) is None:
                message = path + '\n  ' + self.pixmap_cache.errors.get(path, '无法读取图片')
            else:
                continue
            failures.append(message)
            for definition in definitions:
                field = definition.find('path')
                rows.append(('资源错误', message, NavigationTarget(field if field is not None else definition)))
        stats = self.pixmap_cache.stats()
        summary = (f'检查 {len(paths)} 个不同路径，失败 {len(failures)} 个。\n'
                   f'缓存像素预算：{stats["max_bytes"] // (1024 * 1024)} MiB；'
                   f'当前 {stats["bytes"] / (1024 * 1024):.1f} MiB / {stats["entries"]} 项。\n'
                   '点击问题可定位到贴图定义；修复后再次检查以重新加载。\n\n')
        self.canvas.viewport().update()
        return self._show_navigation_report('资源检查', summary + ('\n\n'.join(failures) if failures else '全部路径均可读取。'), rows)

    # ---------- 树 ----------
    def build_tree(self):
        with QSignalBlocker(self.tree_widget):
            self.tree_widget.clear()
            self._tree_items.clear()
            for entry in self._root_entries_for_view():
                self._build_tree_node(entry, None, self.current_page_title)

    def _build_tree_node(self, ui_entry, parent_item, page_filter=None):
        title = ui_entry.findtext("title") or ""
        title2 = ui_entry.findtext("title2") or ""
        id_text = ui_entry.findtext("id") or ""
        label = f"{title}  [{title2}]" if title2 else title
        item = QTreeWidgetItem([label, id_text])
        item.setData(0, Qt.UserRole, ui_entry)
        self._tree_items[ui_entry] = item
        self._sync_layer_row(ui_entry, item)
        if parent_item is None:
            self.tree_widget.addTopLevelItem(item)
        else:
            parent_item.addChild(item)

        children = ui_entry.find("children")
        if children is not None:
            for child in children.findall("uiEntry"):
                if page_filter is not None:
                    ctitle = child.findtext("title") or ""
                    if is_page_title(ctitle) and ctitle != page_filter:
                        continue
                self._build_tree_node(child, item, page_filter)

    def _on_tree_selection(self):
        entries = self.selected_entries()
        with QSignalBlocker(self.canvas.scene):
            self.canvas.scene.clearSelection()
            for entry in entries:
                item = self._find_scene_item(entry)
                if item is not None and item.isVisible():
                    item.setSelected(True)
        self._on_selection_count_changed(len(entries), entries=entries)
        if len(entries) == 1:
            item = self._find_scene_item(entries[0])
            if item is not None and item.isVisible():
                self.canvas.ensureVisible(item)

    def _find_scene_item(self, ui_entry):
        return self._scene_items.get(ui_entry)

    def _find_in_children(self, parent_item, ui_entry):
        if parent_item.ui_entry is ui_entry:
            return parent_item
        for child in parent_item.childItems():
            if isinstance(child, UiEntryItem):
                found = self._find_in_children(child, ui_entry)
                if found is not None:
                    return found
        return None

    # ---------- 画布 ----------
    def rebuild_scene(self, checked=False, selection=None):
        if selection is None:
            selection = self.selected_entries()
        self.props.set_items([])
        self._current_scene_item = None
        with QSignalBlocker(self.canvas.scene):
            self.canvas.scene.clear()
            self._scene_items.clear()
            self.canvas.snap_manager.clear()
            if self.xml_root is not None:
                entries = self._root_entries_for_view()
                for ui_entry in entries:
                    item = UiEntryItem(ui_entry, self.tga_map, self.pixmap_cache,
                                       self, page_filter=self.current_page_title)
                    self.canvas.scene.addItem(item)
                self._apply_view_state([], notify=False)
                for entry in selection:
                    item = self._find_scene_item(entry)
                    if item is not None and item.isVisible():
                        item.setSelected(True)
            rect = self.canvas.scene.itemsBoundingRect()
            self.canvas.scene.setSceneRect(rect.adjusted(-200, -200, 200, 200))
        self._on_selection_count_changed(len(selection), entries=selection)
        self.canvas.viewport().update()

    def _on_selection_count_changed(self, count, entries=None):
        self._inspected_xml = None
        items = (self.canvas.selected_ui_items() if entries is None else
                 [self._scene_items[entry] for entry in entries if entry in self._scene_items])
        self._current_scene_item = items[0] if len(items) == 1 else None
        self.props.set_items(items)
        with QSignalBlocker(self.tree_widget):
            self.tree_widget.clearSelection()
            for item in items:
                row = self._find_tree_item(item.ui_entry)
                if row is not None:
                    row.setSelected(True)
            if len(items) == 1:
                row = self._find_tree_item(items[0].ui_entry)
                if row is not None:
                    self.tree_widget.scrollToItem(row)
        for action in self._layer_actions:
            action.setEnabled(bool(items))
        if len(items) == 1:
            item = items[0]
            suffix = (' [锁定]' if self.is_geometry_locked(item.ui_entry) else '') + (' [隐藏]' if self.is_preview_hidden(item.ui_entry) else '')
            self.statusBar().showMessage(f"{item.ui_entry.findtext('title')}  x={round(item.x())} y={round(item.y())} "
                                        f'w={round(item.width)} h={round(item.height)}{suffix}')
        elif items:
            self.statusBar().showMessage(f'已选中 {len(items)} 个元素')

    def _on_canvas_selected(self, item):
        self._on_selection_count_changed(len(self.canvas.selected_ui_items()))

    def _find_tree_item(self, ui_entry):
        return self._tree_items.get(ui_entry)

    def on_item_modified(self, item):
        if item is self._current_scene_item:
            self.props.refresh_pos_size()

    def on_batch_modified(self, items):
        self.props.set_items(items)
        self.statusBar().showMessage(f"批量修改了 {len(items)} 个元素")

    # ---------- 对齐辅助线 ----------
    def apply_snap(self, item, new_pos):
        parent = item.parentItem()
        siblings = (parent.childItems() if parent is not None else self.canvas.scene.items())
        siblings = [sib for sib in siblings if isinstance(sib, UiEntryItem) and sib.isVisible()
                    and sib is not item and sib.parentItem() is parent and not sib.isSelected()]
        self.canvas.snap_manager.clear()
        # Keep the visual threshold constant while zooming the view.
        scale = abs(self.canvas.transform().m11()) or 1.0
        threshold = UiEntryItem.SNAP_THRESHOLD / scale
        best_x = best_y = None
        w, h = item.width, item.height
        for sib in siblings:
            for offset, target in ((0, sib.x()), (w, sib.x() + sib.width),
                                   (w / 2, sib.x() + sib.width / 2)):
                distance = target - (new_pos.x() + offset)
                if abs(distance) < threshold and (best_x is None or abs(distance) < abs(best_x[0])):
                    best_x = (distance, target, sib)
            for offset, target in ((0, sib.y()), (h, sib.y() + sib.height),
                                   (h / 2, sib.y() + sib.height / 2)):
                distance = target - (new_pos.y() + offset)
                if abs(distance) < threshold and (best_y is None or abs(distance) < abs(best_y[0])):
                    best_y = (distance, target, sib)
        result = QPointF(new_pos)
        if best_x is not None:
            result.setX(result.x() + best_x[0])
        if best_y is not None:
            result.setY(result.y() + best_y[0])
        def scene_point(x, y):
            point = QPointF(x, y)
            return parent.mapToScene(point) if parent is not None else point
        if best_x is not None:
            _, target, sib = best_x
            a = scene_point(target, min(result.y(), sib.y()) - 10)
            b = scene_point(target, max(result.y() + h, sib.y() + sib.height) + 10)
            self.canvas.snap_manager.add_line(a, b)
        if best_y is not None:
            _, target, sib = best_y
            a = scene_point(min(result.x(), sib.x()) - 10, target)
            b = scene_point(max(result.x() + w, sib.x() + sib.width) + 10, target)
            self.canvas.snap_manager.add_line(a, b)
        self.canvas.viewport().update()
        return result

    def clear_snap_guides(self):
        self.canvas.snap_manager.clear()
        self.canvas.viewport().update()

    # ---------- 批量对齐 ----------
    def align_selected(self, mode):
        items = [item for item in self.canvas.selected_ui_items() if not self.is_geometry_locked(item.ui_entry)]
        if len(items) < 2:
            QMessageBox.information(self, '提示', '请至少选中 2 个元素')
            return
        snapshot = self.begin_edit([it.ui_entry for it in items], shallow=True)
        rects = [(it, it.mapRectToScene(it.boundingRect())) for it in items]
        destinations = {}
        if mode in ('left', 'right', 'hcenter', 'top', 'bottom', 'vcenter'):
            if mode == 'left':
                target = min(r.left() for _, r in rects)
            elif mode == 'right':
                target = max(r.right() for _, r in rects)
            elif mode == 'top':
                target = min(r.top() for _, r in rects)
            elif mode == 'bottom':
                target = max(r.bottom() for _, r in rects)
            elif mode == 'hcenter':
                target = sum(r.center().x() for _, r in rects) / len(rects)
            else:
                target = sum(r.center().y() for _, r in rects) / len(rects)
            for it, r in rects:
                delta = {'left': lambda: QPointF(target - r.left(), 0),
                         'right': lambda: QPointF(target - r.right(), 0),
                         'hcenter': lambda: QPointF(target - r.center().x(), 0),
                         'top': lambda: QPointF(0, target - r.top()),
                         'bottom': lambda: QPointF(0, target - r.bottom()),
                         'vcenter': lambda: QPointF(0, target - r.center().y())}[mode]()
                destinations[it] = it.scenePos() + delta
        elif mode in ('hdistribute', 'vdistribute'):
            horizontal = mode == 'hdistribute'
            rects.sort(key=lambda pair: pair[1].left() if horizontal else pair[1].top())
            start = rects[0][1].left() if horizontal else rects[0][1].top()
            end = (max(r.right() for _, r in rects) if horizontal
                   else max(r.bottom() for _, r in rects))
            total = sum(r.width() if horizontal else r.height() for _, r in rects)
            gap = (end - start - total) / (len(rects) - 1)
            cursor = start
            for it, r in rects:
                delta = QPointF(cursor - r.left(), 0) if horizontal else QPointF(0, cursor - r.top())
                destinations[it] = it.scenePos() + delta
                cursor += (r.width() if horizontal else r.height()) + gap
        else:
            return
        # Set ancestors first, then map each child's original scene destination.
        for it in sorted(items, key=lambda item: len(list(item.ui_entry.iterancestors()))):
            parent = it.parentItem()
            pos = parent.mapFromScene(destinations[it]) if parent is not None else destinations[it]
            it.setPos(round(pos.x()), round(pos.y()))
            it._write_pos_to_xml()
        self.finish_edit(snapshot, '批量对齐')

    def _move_item_scene(self, item, dx, dy):
        destination = item.scenePos() + QPointF(dx, dy)
        parent = item.parentItem()
        pos = parent.mapFromScene(destination) if parent is not None else destination
        item.setPos(round(pos.x()), round(pos.y()))
        item._write_pos_to_xml()

    # ---------- 命令栈 ----------
    def begin_edit(self, roots, shallow=False):
        states = {}
        for root in roots:
            if root is not None:
                elements = [root] + list(root) if shallow else root.iter()
                for element in elements:
                    if element not in states:
                        states[element] = capture_element(element)
                for ancestor in root.iterancestors():
                    if ancestor.tag in COUNT_CHILD_TAGS and ancestor not in states:
                        states[ancestor] = capture_element(ancestor)
        selection = self.selected_entries()
        self._document_issues = inspect_document(self.xml_root)
        self._validation_dirty = False
        errors = {tuple(issue[:3]) for issue in self._document_issues if issue[3] == 'error'}
        return states, selection, errors

    def finish_edit(self, snapshot, description, rebuild=False, selection=None, defer=False):
        states, before_selection, before_errors = snapshot
        for element in states:
            sync_count(element)
        changes = []
        for element, before in states.items():
            after = capture_element(element)
            if before != after:
                changes.append((element, before, after))
        if not changes:
            return True
        after_selection = list(before_selection if selection is None else selection)
        command = XmlEditCommand(changes, description, before_selection, after_selection)
        before_issues = self._document_issues
        self._document_issues = inspect_document(self.xml_root)
        introduced = [issue for issue in self._document_issues
                      if issue[3] == 'error' and tuple(issue[:3]) not in before_errors]
        accepted = not introduced
        if accepted:
            self.command_stack.push(command)
        else:
            command.undo_func()
            self._document_issues = before_issues
            self._pending_edit_valid = False
        self._validation_dirty = False
        chosen_selection = after_selection if accepted else before_selection
        if defer:
            # A later selection/page change must win over this queued field refresh.
            self._queue_refresh(changes, None)
            self.update_undo_actions()
        else:
            self.refresh_document(changes=changes, selection=chosen_selection)
        if introduced:
            QMessageBox.warning(self, '修改未应用', format_issues(introduced))
        return accepted

    def _queue_refresh(self, changes, selection):
        if self._pending_refresh is not None:
            self._pending_refresh[0].extend(changes)
            self._pending_refresh[1] = selection
            return
        self._pending_refresh = [list(changes), selection]
        generation = self._document_generation
        def refresh():
            if generation != self._document_generation or self._pending_refresh is None:
                return
            pending = self._pending_refresh
            self._pending_refresh = None
            self.refresh_document(changes=pending[0], selection=pending[1])
        QTimer.singleShot(0, refresh)

    def _changes_require_rebuild(self, changes):
        for element, before, after in changes:
            if before[3] != after[3] or set(before[2]) != set(after[2]):
                return True
            parent = element.getparent()
            if element.tag == 'title' and parent is not None and parent.tag == 'uiEntry':
                if any(is_page_title(value) or value == 'tensho_config_panel' for value in (before[0], after[0])):
                    return True
        return False

    def edit_xml_value(self, element, text, attribute=None, defer=False):
        try:
            if attribute == 'num' and element.tag in COUNT_CHILD_TAGS:
                raise ValueError('数量属性由实际子节点自动维护')
            if attribute is None and (not isinstance(element.tag, str) or len(element) or element.tag in COUNT_CHILD_TAGS):
                raise ValueError('请选择叶子字段或具体属性')
            validate_scalar(element, text, attribute)
            kind = identifier_kind(element) if attribute is None else None
            references = []
            if kind:
                definition = element.getparent()
                index = DocumentIndex(self.xml_root)
                for definitions in index.definitions.values():
                    if any(other is not definition for other in definitions.get(canonical_id(text), [])):
                        raise ValueError('该 ID 已被其他 UI、状态或贴图定义使用')
                for reference in self.xml_root.iter():
                    if reference_kind(reference) == kind:
                        targets = index.resolve(reference)
                        if definition in targets:
                            if len(targets) != 1:
                                raise ValueError('旧 ID 引用不唯一，无法确定应更新哪些引用')
                            references.append(reference)
            snapshot = self.begin_edit([element] + references)
            if attribute is None:
                set_xml_text(element, text)
                for reference in references:
                    set_xml_text(reference, text)
            else:
                element.set(attribute, text)
            return self.finish_edit(snapshot, '修改属性' if attribute else f'修改字段 {element.tag}',
                                    rebuild=True, defer=defer)
        except (ValueError, TypeError) as error:
            self._pending_edit_valid = False
            QMessageBox.warning(self, '输入无效', str(error))
            return False

    def refresh_document(self, rebuild=True, selection=None, changes=None):
        inspected = self._inspected_xml
        if selection is None:
            selection = self.selected_entries()
        self.invalidate_search()
        if self._pending_refresh is not None:
            if changes is not None:
                changes = self._pending_refresh[0] + list(changes)
            self._pending_refresh = None
        self._sync_state_previews(changes)
        full = changes is None or self._changes_require_rebuild(changes)
        if full:
            self._index = DocumentIndex(self.xml_root)
            self._validation_dirty = True
            self.tga_map.clear()
            if self.xml_root is not None:
                for texture in self.xml_root.iter('tga'):
                    ident = texture.findtext('id')
                    if ident:
                        self.tga_map[ident] = texture
            self.refresh_page_list()
            self.build_tree()
            if rebuild:
                self.rebuild_scene(selection=selection)
            else:
                for item in self._scene_items.values():
                    item.refresh_from_xml(recursive=False)
                self._on_selection_count_changed(len(selection), entries=selection)
        else:
            entries = {owner_entry(element) for element, _, _ in changes}
            texture_change = any(element.tag == 'tga' or any(parent.tag == 'tga' for parent in element.iterancestors())
                                 for element, _, _ in changes)
            definition_change = any(identifier_kind(element) for element, _, _ in changes)
            if definition_change:
                self._index = DocumentIndex(self.xml_root)
            if texture_change:
                self.tga_map.clear()
                for texture in self.xml_root.iter('tga'):
                    ident = texture.findtext('id')
                    if ident:
                        self.tga_map[ident] = texture
                entries.update(self._scene_items)
            for entry in entries:
                item = self._find_scene_item(entry)
                if item is not None:
                    item.refresh_from_xml(recursive=False)
                row = self._find_tree_item(entry)
                if row is not None:
                    title, title2 = entry.findtext('title') or '', entry.findtext('title2') or ''
                    row.setText(0, f'{title}  [{title2}]' if title2 else title)
                    row.setText(1, entry.findtext('id') or '')
            if selection is not None:
                selected = set(selection)
                current = {item.ui_entry for item in self.canvas.selected_ui_items()}
                with QSignalBlocker(self.canvas.scene):
                    for entry in current - selected:
                        self._scene_items[entry].setSelected(False)
                    for entry in selected - current:
                        item = self._find_scene_item(entry)
                        if item is not None:
                            item.setSelected(True)
            self._on_selection_count_changed(len(selection), entries=selection)
        if inspected is not None and not selection and belongs_to(self.xml_root, inspected):
            self._inspected_xml = inspected
            self.props.show_xml_element(inspected, '全局 XML')
        self.canvas.scene.setSceneRect(self.canvas.scene.itemsBoundingRect().adjusted(-200, -200, 200, 200))
        self.update_undo_actions()

    def update_undo_actions(self):
        self.undo_action.setEnabled(bool(self.command_stack._undo))
        self.redo_action.setEnabled(bool(self.command_stack._redo))
        self.update_document_state()

    def begin_drag(self, anchor, scene_pos):
        if not self.drag_enabled or self.is_geometry_locked(anchor.ui_entry) or not anchor.isVisible():
            return None
        selected = [item for item in self.canvas.selected_ui_items() if not self.is_geometry_locked(item.ui_entry)]
        selected_set = set(selected)
        roots = []
        for item in selected:
            parent = item.parentItem()
            while parent is not None and parent not in selected_set:
                parent = parent.parentItem()
            if parent is None:
                roots.append(item)
        while anchor not in roots and anchor.parentItem() is not None:
            anchor = anchor.parentItem()
        return {'items': roots, 'anchor': anchor, 'start': QPointF(scene_pos),
                'origins': {it: QPointF(it.scenePos()) for it in roots},
                'snapshot': self.begin_edit([it.ui_entry for it in roots], shallow=True)}

    def move_drag(self, context, scene_pos):
        if context is None:
            return
        anchor = context['anchor']
        if anchor not in context['origins']:
            return
        delta = scene_pos - context['start']
        desired_scene = context['origins'][anchor] + delta
        parent = anchor.parentItem()
        desired = parent.mapFromScene(desired_scene) if parent is not None else desired_scene
        snapped = self.apply_snap(anchor, desired)
        snapped_scene = parent.mapToScene(snapped) if parent is not None else snapped
        delta = snapped_scene - context['origins'][anchor]
        for item in context['items']:
            destination = context['origins'][item] + delta
            parent = item.parentItem()
            item.setPos(parent.mapFromScene(destination) if parent is not None else destination)

    def end_drag(self, context):
        if context is None:
            return
        for item in context['items']:
            item.setPos(round(item.x()), round(item.y()))
            item._write_pos_to_xml()
        self.finish_edit(context['snapshot'], '移动' if len(context['items']) == 1 else '批量移动')

    def cancel_active_gesture(self):
        active = False
        for item in self.canvas.scene.items():
            if not isinstance(item, UiEntryItem):
                continue
            active = active or item._drag_context is not None or item._resizing
            item._drag_context = None
            item._resizing = False
            item._resize_snapshot = None
        self.clear_snap_guides()
        if active:
            for item in self.canvas.scene.items():
                if isinstance(item, UiEntryItem) and item.parentItem() is None:
                    item.refresh_from_xml()

    def undo(self):
        self.cancel_active_gesture()
        cmd = self.command_stack.undo()
        if cmd is not None:
            self._validation_dirty = True
            self.refresh_document(selection=cmd.before_selection, changes=cmd.changes)
            self.statusBar().showMessage(f'撤销: {cmd.description}')
        self.update_undo_actions()

    def redo(self):
        self.cancel_active_gesture()
        cmd = self.command_stack.redo()
        if cmd is not None:
            self._validation_dirty = True
            self.refresh_document(selection=cmd.after_selection, changes=cmd.changes)
            self.statusBar().showMessage(f'重做: {cmd.description}')
        self.update_undo_actions()

    # ---------- 节点操作 ----------
    def _get_children_container(self, ui_entry):
        children = ui_entry.find("children")
        if children is None:
            children = etree.SubElement(ui_entry, "children")
            children.set("num", "0")
        return children

    def _new_ui_entry(self, title="new_entry"):
        entry = etree.Element("uiEntry")
        entry_id = allocate_id(self.xml_root)
        etree.SubElement(entry, "id").text = entry_id
        etree.SubElement(entry, "title").text = title
        etree.SubElement(entry, "title2").text = ""
        etree.SubElement(entry, "string10").text = title
        etree.SubElement(entry, "xOff").text = "0"
        etree.SubElement(entry, "yOff").text = "0"
        for f in ["flag1","flag2","flag3","flag11","flag12","flag13","flag14",
                  "flag6","flag7","flag8","flag9","flag15"]:
            etree.SubElement(entry, f).text = "0"
        etree.SubElement(entry, "parentName").text = ""
        etree.SubElement(entry, "int1").text = "-1"
        etree.SubElement(entry, "tooltip").text = ""
        etree.SubElement(entry, "tooltipText").text = ""
        etree.SubElement(entry, "int3").text = "0"
        etree.SubElement(entry, "int4").text = "0"
        etree.SubElement(entry, "flag4").text = "0"
        etree.SubElement(entry, "script").text = ""
        tgas = etree.SubElement(entry, "tgas"); tgas.set("num", "0")
        etree.SubElement(entry, "int5").text = "0"
        etree.SubElement(entry, "int6").text = "0"
        states = etree.SubElement(entry, "states"); states.set("num", "1")
        state = etree.SubElement(states, "state")
        etree.SubElement(state, "id").text = allocate_id(self.xml_root, reserved={entry_id})
        etree.SubElement(state, "title").text = "NewState"
        etree.SubElement(state, "width").text = "100"
        etree.SubElement(state, "height").text = "100"
        etree.SubElement(state, "stateText").text = ""
        etree.SubElement(state, "font").text = "bardi_10, Normal"
        etree.SubElement(state, "textAlphaMultiply").text = "-16777216"
        etree.SubElement(state, "twui").text = "Default Font Category"
        tgaUses = etree.SubElement(state, "tgaUses"); tgaUses.set("num", "0")
        etree.SubElement(entry, "int26").text = "0"
        etree.SubElement(entry, "events")
        etree.SubElement(entry, "eventsEnd").text = "events_end"
        etree.SubElement(entry, "int27").text = "10"
        effects = etree.SubElement(entry, "effects"); effects.set("num", "0")
        children = etree.SubElement(entry, "children"); children.set("num", "0")
        etree.SubElement(entry, "template").text = ""
        etree.SubElement(entry, "flag5").text = "0"
        return entry

    def add_child_to(self, item):
        title, ok = QInputDialog.getText(self, '添加子节点', '节点名称:', text='new_entry')
        if not ok or not title.strip():
            return
        snapshot = self.begin_edit([item.ui_entry])
        children = self._get_children_container(item.ui_entry)
        new_entry = self._new_ui_entry(title.strip())
        children.append(new_entry)
        children.set('num', str(len(children.findall('uiEntry'))))
        self.finish_edit(snapshot, '添加子节点', rebuild=True, selection=[new_entry])

    def add_sibling_to(self, item):
        parent_item = item.parentItem()
        if not isinstance(parent_item, UiEntryItem):
            QMessageBox.information(self, '提示', '根节点没有父节点')
            return
        title, ok = QInputDialog.getText(self, '添加同级节点', '节点名称:', text='new_entry')
        if not ok or not title.strip():
            return
        snapshot = self.begin_edit([parent_item.ui_entry])
        children = self._get_children_container(parent_item.ui_entry)
        new_entry = self._new_ui_entry(title.strip())
        children.insert(list(children).index(item.ui_entry) + 1, new_entry)
        children.set('num', str(len(children.findall('uiEntry'))))
        self.finish_edit(snapshot, '添加同级节点', rebuild=True, selection=[new_entry])

    def duplicate_item(self, item):
        entry = item.ui_entry
        parent = entry.getparent()
        if parent is None:
            QMessageBox.information(self, '提示', '无法复制 XML 文档根元素')
            return False
        try:
            new_entry = clone_ui_entry(self.xml_root, entry)
        except ValueError as error:
            QMessageBox.warning(self, '无法复制', str(error))
            return False
        snapshot = self.begin_edit([parent])
        parent.insert(list(parent).index(entry) + 1, new_entry)
        return self.finish_edit(snapshot, '复制节点', rebuild=True, selection=[new_entry])

    def delete_item(self, item):
        entry = item.ui_entry
        parent = entry.getparent()
        if parent is None:
            QMessageBox.information(self, '提示', '无法删除 XML 文档根元素')
            return
        title = entry.findtext('title') or ''
        if QMessageBox.question(self, '删除', f'确认删除 {title} 吗？') != QMessageBox.Yes:
            return
        snapshot = self.begin_edit([parent])
        parent.remove(entry)
        if parent.tag == 'children':
            parent.set('num', str(len(parent.findall('uiEntry'))))
        selection = [parent.getparent()] if parent.tag == 'children' else []
        self.finish_edit(snapshot, '删除节点', rebuild=True, selection=selection)

    def paste_ui_entry_to_root(self):
        if self.clipboard_ui_entry is None or self.xml_root is None:
            return False
        try:
            new_entry = clone_ui_entry(self.xml_root, self.clipboard_ui_entry)
        except ValueError as error:
            QMessageBox.warning(self, '无法粘贴', str(error))
            return False
        snapshot = self.begin_edit([self.xml_root])
        self.xml_root.append(new_entry)
        return self.finish_edit(snapshot, '粘贴节点', rebuild=True, selection=[new_entry])

    # ---------- 状态机 ----------
    def show_state_machine(self):
        self.show_state_editor()


# =========================================================
# 入口
# =========================================================
def main():
    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    win = MainWindow()

    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        win._load_xml(sys.argv[1])

    win.show()
    QTimer.singleShot(0, win.offer_startup_recovery)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
