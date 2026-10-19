"""Resource browser and component template actions for the editor."""
from PIL import Image
from PySide6.QtCore import Qt, QTimer, QSaveFile, QIODevice
from PySide6.QtGui import QImage, QPixmap
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QTreeWidget,
    QTreeWidgetItem, QLabel, QPushButton, QLineEdit, QSplitter, QWidget,
    QFileDialog, QMessageBox, QDialogButtonBox)
from lxml import etree

from .assets import (resource_records, normalize_path, prefix_plan, game_path,
                     make_template, read_template, instantiate_template)
from .document import owner_entry, validate_scalar
from .navigation import belongs_to
from .theme import icon, primary


class ResourceBrowser(QDialog):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor
        self.generation = editor._document_generation
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.setWindowTitle('资源浏览器 · 全部页面')
        self.resize(980, 620)
        layout = QVBoxLayout(self)
        self.filter = QLineEdit()
        self.filter.setPlaceholderText('筛选贴图路径或 ID')
        layout.addWidget(self.filter)
        splitter = QSplitter()
        layout.addWidget(splitter)
        self.resources = QTreeWidget()
        self.resources.setHeaderLabels(['贴图 ID', '路径', '引用数'])
        self.resources.setColumnWidth(0, 90)
        self.resources.setColumnWidth(1, 350)
        splitter.addWidget(self.resources)
        detail = QWidget()
        right = QVBoxLayout(detail)
        self.preview = QLabel('选择贴图查看缩略图')
        self.preview.setObjectName('ResourcePreview')
        self.preview.setAlignment(Qt.AlignCenter)
        self.preview.setMinimumHeight(145)
        right.addWidget(self.preview)
        self.metadata = QLabel()
        self.metadata.setWordWrap(True)
        self.metadata.setTextFormat(Qt.PlainText)
        right.addWidget(self.metadata)
        self.usages = QTreeWidget()
        self.usages.setHeaderLabels(['使用位置（双击定位）', '状态 / 字段'])
        self.usages.setColumnWidth(0, 280)
        self.usages.setColumnWidth(1, 120)
        right.addWidget(self.usages)
        splitter.addWidget(detail)
        splitter.setSizes([570, 410])
        bar = QHBoxLayout()
        layout.addLayout(bar)
        for text, callback in [('定位贴图定义', self.locate_definition),
                               ('替换选中路径…', self.replace),
                               ('批量修正目录前缀…', editor.show_path_repair),
                               ('刷新资源', self.refresh_resources)]:
            button = QPushButton(text)
            button.clicked.connect(callback)
            bar.addWidget(button)
        self.filter.textChanged.connect(self.apply_filter)
        self.resources.currentItemChanged.connect(self.show_record)
        self.usages.itemDoubleClicked.connect(self.locate_usage)
        self._refresh_timer = QTimer(self)
        self._refresh_timer.setSingleShot(True)
        self._refresh_timer.timeout.connect(self.reload)
        self.reload()

    def current_record(self):
        row = self.resources.currentItem()
        return row.data(0, Qt.UserRole) if row else None

    def schedule(self):
        self._refresh_timer.start(0)

    def reload(self):
        if self.generation != self.editor._document_generation or self.editor.xml_root is None:
            self.close()
            return
        previous = self.current_record()
        selected = previous.definition if previous else None
        self.resources.clear()
        self.usages.clear()
        self.preview.clear()
        self.metadata.clear()
        choice = None
        for record in resource_records(self.editor.xml_root):
            row = QTreeWidgetItem([record.definition.findtext('id') or '', record.path, str(len(record.usages))])
            row.setData(0, Qt.UserRole, record)
            row.setToolTip(1, record.path)
            self.resources.addTopLevelItem(row)
            if record.definition is selected:
                choice = row
        self.apply_filter()
        self.resources.setCurrentItem(choice or self.resources.topLevelItem(0))

    def apply_filter(self):
        query = self.filter.text().casefold()
        for n in range(self.resources.topLevelItemCount()):
            row = self.resources.topLevelItem(n)
            row.setHidden(query not in (row.text(0) + ' ' + row.text(1)).casefold())

    def show_record(self, *unused):
        self.usages.clear()
        self.preview.clear()
        record = self.current_record()
        if record is None:
            return
        real = self.editor.resolver.resolve(record.path)
        try:
            if real is None:
                raise FileNotFoundError('当前资源目录中未找到文件')
            with Image.open(real) as image:
                dimensions = f'{image.width} × {image.height}'
                image.thumbnail((256, 144))
                image = image.convert('RGBA')
                preview = QImage(image.tobytes(), image.width, image.height, QImage.Format_RGBA8888).copy()
            self.preview.setPixmap(QPixmap.fromImage(preview))
            self.metadata.setText(f'尺寸：{dimensions}\n文件：{real}\n引用字段：{len(record.usages)} 处')
        except (OSError, ValueError, Image.DecompressionBombError) as error:
            self.preview.setText('无法预览')
            self.metadata.setText(str(error))
        for reference in record.usages:
            entry = owner_entry(reference)
            names = [e.findtext('title') or e.findtext('id') or 'UI' for e in reference.iterancestors('uiEntry')]
            label = ' / '.join(reversed(names)) if entry is not None else '全局字段'
            visible = label.removeprefix('tensho_config_panel / ')
            state = next(reference.iterancestors('state'), None)
            field = ((state.findtext('title') or '') + ' / ' if state is not None else '') + str(reference.tag)
            row = QTreeWidgetItem([visible, field])
            row.setToolTip(0, label)
            row.setToolTip(1, field)
            row.setData(0, Qt.UserRole, reference)
            self.usages.addTopLevelItem(row)

    def locate_definition(self):
        record = self.current_record()
        if record:
            self.editor.navigate_to_element(record.path_element if record.path_element is not None else record.definition,
                                            generation=self.generation)

    def locate_usage(self, row, *unused):
        self.editor.navigate_to_element(row.data(0, Qt.UserRole), generation=self.generation)

    def refresh_resources(self):
        self.editor.pixmap_cache.clear()
        self.editor.canvas.scene.update()
        self.reload()

    def replace(self):
        record = self.current_record()
        if record is None or record.path_element is None:
            return
        filename, _ = QFileDialog.getOpenFileName(self, '选择替换贴图', '', '图片 (*.tga *.png *.dds *.jpg *.bmp);;所有文件 (*)')
        if not filename:
            return
        proposed = game_path(filename, self.editor.resolver)
        dialog = PathRepair(self.editor, [(record.path_element, record.path, proposed)], '替换贴图路径')
        dialog.exec()


class PathRepair(QDialog):
    def __init__(self, editor, plan=None, title='批量修正贴图目录前缀'):
        super().__init__(editor)
        self.editor = editor
        self.generation = editor._document_generation
        self.fixed = plan is not None
        self.plan = plan or []
        self.setWindowTitle(title)
        self.resize(900, 460)
        layout = QVBoxLayout(self)
        note = QLabel('先检查新路径，再应用。整批修改可一次撤销。资源目录内的文件使用相对路径，其他文件使用绝对路径。')
        note.setWordWrap(True)
        layout.addWidget(note)
        if not self.fixed:
            bar = QHBoxLayout()
            self.old = QLineEdit()
            self.old.setPlaceholderText('原目录前缀，例如 ui/old')
            self.new = QLineEdit()
            self.new.setPlaceholderText('新目录前缀；留空可移除原前缀')
            bar.addWidget(self.old)
            bar.addWidget(self.new)
            preview = QPushButton('生成预览')
            preview.clicked.connect(self.build)
            bar.addWidget(preview)
            layout.addLayout(bar)
            self.old.textChanged.connect(self.invalidate)
            self.new.textChanged.connect(self.invalidate)
        self.table = QTreeWidget()
        self.table.setHeaderLabels(['原路径', '新路径', '文件状态'])
        self.table.setColumnWidth(0, 300)
        self.table.setColumnWidth(1, 350)
        layout.addWidget(self.table)
        self.status = QLabel()
        layout.addWidget(self.status)
        buttons = QDialogButtonBox(QDialogButtonBox.Apply | QDialogButtonBox.Cancel)
        buttons.button(QDialogButtonBox.Cancel).setText('取消')
        self.apply_button = buttons.button(QDialogButtonBox.Apply)
        primary(self.apply_button)
        self.apply_button.setText('应用路径修改')
        self.apply_button.clicked.connect(self.apply)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        self.render()

    def invalidate(self):
        self.plan = []
        self.render()

    def build(self):
        try:
            self.plan = prefix_plan(self.editor.xml_root, self.old.text(), self.new.text())
            self.render()
        except ValueError as error:
            self.status.setText(str(error))

    def render(self):
        self.table.clear()
        missing = 0
        for element, old, new in self.plan:
            found = self.editor.resolver.resolve(new) is not None
            missing += not found
            self.table.addTopLevelItem(QTreeWidgetItem([old, new, '文件存在' if found else '未找到文件']))
        self.status.setText(f'将修改 {len(self.plan)} 个定义；{missing} 个新路径未找到文件。贴图文件本身不会被复制。')
        self.apply_button.setEnabled(bool(self.plan))

    def apply(self):
        try:
            if self.generation != self.editor._document_generation:
                raise ValueError('文档已切换，请重新生成预览')
            if self.editor.apply_resource_plan(self.plan):
                self.accept()
        except ValueError as error:
            QMessageBox.warning(self, '修改未应用', str(error))


class AssetsController:
    def invalidate_search(self):
        self._invalidate_assets()
        super().invalidate_search()

    def _reset_navigation(self):
        self._reset_assets()
        super()._reset_navigation()

    def _flush_pending_refresh(self):
        self.cancel_active_gesture()
        if self._pending_refresh is not None:
            self.refresh_document(changes=[], selection=self.selected_entries())

    def _init_assets(self):
        self.resource_browser = None
        menu = self.menuBar().addMenu('资源与模板')
        for title, callback in [('资源浏览器…', self.show_resource_browser),
                                ('批量修正贴图目录前缀…', self.show_path_repair),
                                ('保存选中节点为组件模板…', self.save_component_template),
                                ('插入组件模板…', self.insert_component_template)]:
            action = menu.addAction(title)
            action.setIcon(icon('image' if callback == self.show_resource_browser else 'folder' if callback == self.show_path_repair else 'copy'))
            action.triggered.connect(callback)

    def _reset_assets(self):
        if self.resource_browser is not None:
            self.resource_browser.close()
            self.resource_browser = None

    def _invalidate_assets(self):
        if self.resource_browser is not None:
            self.resource_browser.schedule()

    def show_resource_browser(self):
        if self.xml_root is None:
            return
        if self.resource_browser is None:
            dialog = ResourceBrowser(self)
            self.resource_browser = dialog
            dialog.destroyed.connect(lambda: self._browser_destroyed(dialog))
        self.resource_browser.show()
        self.resource_browser.raise_()

    def _browser_destroyed(self, dialog):
        if self.resource_browser is dialog:
            self.resource_browser = None

    def show_path_repair(self):
        if self.xml_root is not None and self.props.flush_pending_edits():
            PathRepair(self).exec()

    def apply_resource_plan(self, plan):
        if not self.props.flush_pending_edits():
            return False
        self._flush_pending_refresh()
        if not plan:
            return True
        seen = set()
        for element, old, new in plan:
            if (element in seen or not belongs_to(self.xml_root, element) or element.tag != 'path'
                    or element.getparent().tag != 'tga' or element.text != old or len(element)):
                raise ValueError('路径预览已失效，请刷新后重试')
            seen.add(element)
            if normalize_path(new) != new:
                raise ValueError('新路径格式无效')
            validate_scalar(element, new)
        snapshot = self.begin_edit([element for element, _, _ in plan])
        for element, old, new in plan:
            element.text = new
        self.pixmap_cache.clear()
        return self.finish_edit(snapshot, '替换贴图路径' if len(plan) == 1 else '批量修正贴图路径')

    def save_component_template(self):
        if self.xml_root is None or not self.props.flush_pending_edits():
            return
        self._flush_pending_refresh()
        entries = self.selected_entries()
        if len(entries) != 1:
            QMessageBox.information(self, '组件模板', '请在层级树或画布中选中一个 UI 节点')
            return
        try:
            payload, warnings = make_template(self.xml_root, entries[0])
            filename, _ = QFileDialog.getSaveFileName(self, '保存组件模板（含贴图定义，图片文件需另备）',
                self.settings.value('templates/last_directory', ''), 'Tensho 组件 (*.tensho.xml)')
            if not filename:
                return
            file = QSaveFile(filename)
            if not file.open(QIODevice.WriteOnly) or file.write(payload) != len(payload) or not file.commit():
                raise OSError(file.errorString())
            import os
            self.settings.setValue('templates/last_directory', os.path.dirname(filename))
            suffix = '；未知引用字段保持原文：' + ', '.join(warnings) if warnings else ''
            QMessageBox.information(self, '组件模板已保存', '已保存节点、子节点和所需贴图定义。图片文件需在目标资源目录中可用。脚本与未知引用需自行核对' + suffix)
        except (ValueError, OSError, etree.LxmlError) as error:
            QMessageBox.warning(self, '模板未保存', str(error))

    def insert_component_template(self):
        if self.xml_root is None or not self.props.flush_pending_edits():
            return
        self._flush_pending_refresh()
        entries = self.selected_entries()
        if len(entries) != 1:
            QMessageBox.information(self, '组件模板', '请选择一个父 UI 节点；模板将插入为它的子节点')
            return
        filename, _ = QFileDialog.getOpenFileName(self, '选择组件模板（插入为选中节点的子节点）',
            self.settings.value('templates/last_directory', ''), 'Tensho 组件 (*.xml)')
        if not filename:
            return
        try:
            component = read_template(filename)
            if self.insert_template_under(component, entries[0]):
                import os
                self.settings.setValue('templates/last_directory', os.path.dirname(filename))
                self.statusBar().showMessage('已插入组件模板；贴图文件、脚本和未知引用请在目标环境中核对', 10000)
        except (ValueError, OSError, etree.LxmlError) as error:
            QMessageBox.warning(self, '模板未插入', str(error))

    def insert_template_under(self, component, parent):
        if not self.props.flush_pending_edits():
            return False
        self._flush_pending_refresh()
        if not belongs_to(self.xml_root, parent) or parent.tag != 'uiEntry':
            raise ValueError('目标父节点已失效')
        new_entry = instantiate_template(self.xml_root, component)
        snapshot = self.begin_edit([parent])
        self._get_children_container(parent).append(new_entry)
        return self.finish_edit(snapshot, '插入组件模板', selection=[new_entry])
