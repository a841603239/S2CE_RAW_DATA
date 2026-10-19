"""Explicit scope selection and a read-only difference preview for batch edits."""
from PySide6.QtCore import Qt
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QFormLayout,
    QComboBox, QLineEdit, QLabel, QCheckBox, QPushButton, QTreeWidget,
    QTreeWidgetItem, QDialogButtonBox, QMessageBox, QColorDialog)

from .state_editing import build_batch_plan, scoped_entries
from .theme import primary


OPERATIONS = (
    ('贴图颜色（RGB 倍乘）', 'tint'),
    ('贴图透明度（0–255）', 'opacity'),
    ('文字颜色：fontColor（ARGB）', 'fontColor'),
    ('文字颜色：textAlphaMultiply（ARGB）', 'textAlphaMultiply'),
    ('字体', 'font'),
    ('贴图引用', 'texture'),
    ('UI 节点名称', 'entry_name'),
    ('状态名称', 'state_name'),
)


class BatchEditDialog(QDialog):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor
        self.generation = editor._document_generation
        self.selected = list(editor.selected_entries())
        self.visible = list(editor._scene_items)
        self.previews = dict(editor._preview_states)
        for entry, item in editor._scene_items.items():
            state = item._current_state()
            if state is not None:
                self.previews[entry] = state.findtext('title') or ''
        self.plan = None
        self.setWindowTitle('批量编辑 · 范围与差异预览')
        self.resize(1100, 740)
        layout = QVBoxLayout(self)
        note = QLabel('选择节点和状态范围，生成差异预览后再应用。贴图修改只改使用位置的引用，不改共享资源定义。')
        note.setWordWrap(True)
        layout.addWidget(note)
        form = QFormLayout()
        layout.addLayout(form)
        self.scope = QComboBox()
        for title, value in [('仅选中节点', 'selected'), ('选中节点及全部后代', 'descendants'),
                             ('当前预览中的节点（含隐藏节点）', 'preview'), ('整个文档（全部页面）', 'document')]:
            self.scope.addItem(title, value)
        form.addRow('节点范围', self.scope)
        row = QHBoxLayout()
        self.state_mode = QComboBox()
        for title, value in [('全部状态', 'all'), ('各节点当前预览状态', 'preview'), ('指定名称的状态', 'named')]:
            self.state_mode.addItem(title, value)
        self.state_name = QLineEdit()
        self.state_name.setPlaceholderText('状态名称完全匹配；留空可匹配空名称状态')
        row.addWidget(self.state_mode)
        row.addWidget(self.state_name, 1)
        form.addRow('状态范围', row)
        self.operation = QComboBox()
        for title, value in OPERATIONS:
            self.operation.addItem(title, value)
        form.addRow('修改内容', self.operation)
        row = QHBoxLayout()
        self.rename_mode = QComboBox()
        for title, value in [('添加前缀', 'prefix'), ('添加后缀', 'suffix'), ('文字查找替换', 'replace')]:
            self.rename_mode.addItem(title, value)
        self.find = QLineEdit()
        self.find.setPlaceholderText('要替换的文字（字面匹配，区分大小写）')
        row.addWidget(self.rename_mode)
        row.addWidget(self.find, 1)
        form.addRow('名称修改方式', row)
        row = QHBoxLayout()
        self.value = QLineEdit()
        self.color_button = QPushButton('选择颜色…')
        self.color_button.clicked.connect(self.choose_color)
        row.addWidget(self.value, 1)
        row.addWidget(self.color_button)
        form.addRow('新值 / 前后缀', row)
        self.texture = QComboBox()
        self.texture.addItem('请选择目标贴图定义', None)
        for definition in editor.xml_root.iter('tga'):
            self.texture.addItem(f'ID {definition.findtext("id") or "?"} · {definition.findtext("path") or "(空路径)"}', definition)
        form.addRow('目标贴图', self.texture)
        self.create_missing = QCheckBox('补齐缺失字段（默认跳过；不创建状态或贴图使用位置）')
        layout.addWidget(self.create_missing)
        self.help = QLabel()
        self.help.setWordWrap(True)
        layout.addWidget(self.help)
        preview = QPushButton('生成差异预览')
        preview.clicked.connect(self.build)
        layout.addWidget(preview)
        self.changes = QTreeWidget()
        self.changes.setHeaderLabels(['节点 / 状态', '字段', '原值', '新值', '操作'])
        for n, width in enumerate((340, 150, 210, 210, 80)):
            self.changes.setColumnWidth(n, width)
        layout.addWidget(self.changes, 1)
        self.status = QLabel('尚未生成预览')
        self.status.setWordWrap(True)
        layout.addWidget(self.status)
        buttons = QDialogButtonBox(QDialogButtonBox.Apply | QDialogButtonBox.Cancel)
        self.apply_button = buttons.button(QDialogButtonBox.Apply)
        primary(self.apply_button)
        self.apply_button.setText('应用整批修改')
        self.apply_button.setEnabled(False)
        self.apply_button.clicked.connect(self.apply)
        buttons.button(QDialogButtonBox.Cancel).setText('取消')
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)
        for combo in (self.scope, self.state_mode, self.operation, self.rename_mode, self.texture):
            combo.currentIndexChanged.connect(self.options_changed)
        for edit in (self.state_name, self.find, self.value):
            edit.textChanged.connect(self.invalidate)
        self.create_missing.toggled.connect(self.invalidate)
        self.options_changed()

    def invalidate(self, *unused):
        self.plan = None
        self.changes.clear()
        self.status.setText('选项已变化，请重新生成差异预览')
        self.apply_button.setEnabled(False)

    def options_changed(self, *unused):
        self.invalidate()
        op = self.operation.currentData()
        naming = op in ('entry_name', 'state_name')
        state_enabled = op != 'entry_name'
        self.rename_mode.setEnabled(naming)
        self.find.setEnabled(naming and self.rename_mode.currentData() == 'replace')
        self.state_mode.setEnabled(state_enabled)
        self.state_name.setEnabled(state_enabled and self.state_mode.currentData() == 'named')
        self.texture.setEnabled(op == 'texture')
        self.value.setEnabled(op != 'texture')
        self.color_button.setVisible(op in ('tint', 'fontColor', 'textAlphaMultiply'))
        self.create_missing.setEnabled(op != 'texture')
        placeholders = {'tint': '#RRGGBB，例如 #80C0FF', 'opacity': '0 为透明，255 为不透明',
            'fontColor': '#AARRGGBB，例如 #FFFFFFFF（白色、不透明）',
            'textAlphaMultiply': '#AARRGGBB，例如 #FFFFFFFF（白色、不透明）',
            'font': '例如 bardi_10, Normal', 'entry_name': '前缀、后缀或替换后的文字',
            'state_name': '前缀、后缀或替换后的文字'}
        self.value.setPlaceholderText(placeholders.get(op, ''))
        if op in ('fontColor', 'textAlphaMultiply'):
            self.help.setText('文字颜色只写入所选 XML 字段。样例的两种字段布局并不一致，请按目标文件选择；ARGB 的 AA 为透明度。')
        elif op == 'texture':
            self.help.setText('将范围内各状态的所有现有 tgaUse 引用指向所选贴图；资源定义路径、位置、尺寸和倍乘颜色保持不变。')
        elif naming:
            self.help.setText('名称按字面修改，不执行脚本或正则。状态名称在同一 UI 节点内保持唯一。')
        else:
            self.help.setText('未匹配的节点/状态和未勾选补齐的缺失字段会跳过。锁定和隐藏不阻止明确的字段编辑。')

    def choose_color(self):
        alpha = self.operation.currentData() != 'tint'
        color = QColor(self.value.text())
        if not color.isValid():
            color = QColor('white')
        chosen = QColorDialog.getColor(color, self, '选择批量颜色',
            QColorDialog.ShowAlphaChannel if alpha else QColorDialog.ColorDialogOption(0))
        if chosen.isValid():
            self.value.setText(chosen.name(QColor.HexArgb if alpha else QColor.HexRgb).upper())

    def build(self):
        self.invalidate()
        try:
            if self.generation != self.editor._document_generation or self.editor.xml_root is None:
                raise ValueError('文档已切换，请重新打开批量编辑')
            if not self.editor.props.flush_pending_edits():
                return
            self.editor._flush_pending_refresh()
            entries = scoped_entries(self.editor.xml_root, self.selected, self.visible, self.scope.currentData())
            self.plan = build_batch_plan(self.editor.xml_root, entries, self.previews,
                operation=self.operation.currentData(), value=self.value.text(),
                state_mode=self.state_mode.currentData(), state_title=self.state_name.text(),
                create_missing=self.create_missing.isChecked() and self.create_missing.isEnabled(),
                rename_mode=self.rename_mode.currentData(), find=self.find.text(), texture=self.texture.currentData())
            for patch in self.plan.patches[:1000]:
                old = '(字段缺失)' if patch.element is None else (patch.before or '(空)')
                values = [patch.label, patch.tag, old,
                          patch.after, '新增字段' if patch.element is None else '修改']
                row = QTreeWidgetItem(values)
                for n, text in enumerate(values):
                    row.setToolTip(n, text)
                row.setToolTip(0, patch.label + '\n' + patch.parent.getroottree().getpath(patch.parent))
                self.changes.addTopLevelItem(row)
            count = len(self.plan.patches)
            self.status.setText(f'范围：{self.plan.entry_count} 个 UI 节点、{self.plan.state_count} 个状态；'
                f'实际修改 {count} 个字段，跳过缺失字段/无贴图使用 {self.plan.skipped} 处。' +
                ('列表显示前 1000 项；应用覆盖全部预览结果。' if count > 1000 else '整批修改可一次撤销。'))
            self.apply_button.setEnabled(bool(count))
        except (ValueError, TypeError) as error:
            self.plan = None
            self.status.setText(str(error))

    def apply(self):
        if self.plan is None:
            return
        try:
            if self.generation != self.editor._document_generation:
                raise ValueError('文档已切换，请重新打开批量编辑')
            if self.editor.apply_batch_plan(self.plan):
                self.accept()
        except (ValueError, TypeError) as error:
            self.invalidate()
            self.status.setText(str(error))
            QMessageBox.warning(self, '批量修改未应用', str(error))
