"""State and transition editor; all writes go through the main command stack."""
from PySide6.QtCore import Qt
from PySide6.QtGui import QIntValidator
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QFormLayout,
    QLabel, QTreeWidget, QTreeWidgetItem, QPushButton, QSplitter, QWidget,
    QTabWidget, QDialogButtonBox, QLineEdit, QComboBox, QInputDialog, QMessageBox)

from .state_editing import own_states, state_referrers, TRANSITION_FIELDS
from .navigation import belongs_to
from .theme import icon, destructive


def state_caption(state):
    return f'{state.findtext("title") or "(空名称)"}  [ID {state.findtext("id") or "?"}]'


class TransitionDialog(QDialog):
    def __init__(self, entry, transition=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle('编辑状态转换' if transition is not None else '新增状态转换')
        self.resize(520, 380)
        layout = QVBoxLayout(self)
        note = QLabel('目标状态限定为当前 UI 节点。type 及参数保留 XML 原值；未列出的字段保持不变。')
        note.setWordWrap(True)
        layout.addWidget(note)
        form = QFormLayout()
        layout.addLayout(form)
        self.fields = {}
        for tag in TRANSITION_FIELDS:
            value = transition.findtext(tag) if transition is not None else None
            if tag == 'stateIDRef':
                field = QComboBox()
                for state in own_states(entry):
                    field.addItem(state_caption(state), state.findtext('id'))
                position = field.findData(value)
                if position >= 0:
                    field.setCurrentIndex(position)
                elif transition is not None:
                    field.insertItem(0, f'失效引用：{value!r}（请选择有效状态）', None)
                    field.setCurrentIndex(0)
            else:
                field = QLineEdit(value if value is not None else ('0' if tag in ('type', 'int1', 'int2', 'int3') else ''))
                if tag in ('type', 'int1', 'int2', 'int3'):
                    field.setValidator(QIntValidator(-2147483648, 2147483647, self))
            self.fields[tag] = field
            form.addRow('目标状态' if tag == 'stateIDRef' else tag, field)
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.button(QDialogButtonBox.Ok).setText('应用转换')
        buttons.button(QDialogButtonBox.Cancel).setText('取消')
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def values(self):
        return {tag: field.currentData() if tag == 'stateIDRef' else field.text()
                for tag, field in self.fields.items()}


class DeleteStateDialog(QDialog):
    def __init__(self, entry, state, references, parent=None):
        super().__init__(parent)
        self.setWindowTitle('删除状态并替换引用')
        self.resize(650, 370)
        layout = QVBoxLayout(self)
        label = QLabel(f'删除：{state_caption(state)}\n有 {len(references)} 个保留字段引用此状态。请选择同一节点的替代状态。')
        label.setWordWrap(True)
        layout.addWidget(label)
        self.replacement = QComboBox()
        self.replacement.addItem('请选择替代状态', None)
        for other in own_states(entry):
            if other is not state:
                self.replacement.addItem(state_caption(other), other)
        layout.addWidget(self.replacement)
        table = QTreeWidget()
        table.setHeaderLabels(['来源状态 / 引用字段（悬停查看完整路径）', '当前值'])
        table.setColumnWidth(0, 460)
        for ref in references:
            source_state = next(ref.iterancestors('state'), None)
            caption = (source_state.findtext('title') or '(空状态名)') if source_state is not None else (entry.findtext('title') or 'UI')
            if ref.getparent().tag == 'transition' and source_state is not None:
                caption += f' / 转换{source_state.findall("transitions/transition").index(ref.getparent()) + 1}'
            row = QTreeWidgetItem([caption + ' / ' + str(ref.tag), ref.text or ''])
            row.setToolTip(0, ref.getroottree().getpath(ref))
            table.addTopLevelItem(row)
        layout.addWidget(table)
        note = QLabel('转换和 int4 等已知引用会一同更新；脚本、未知整数及未知引用保留原文，需自行核对。')
        note.setWordWrap(True)
        layout.addWidget(note)
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        ok = buttons.button(QDialogButtonBox.Ok)
        ok.setText('删除并替换引用')
        ok.setEnabled(False)
        self.replacement.currentIndexChanged.connect(lambda: ok.setEnabled(self.replacement.currentData() is not None))
        buttons.button(QDialogButtonBox.Cancel).setText('取消')
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)


class StateEditorDialog(QDialog):
    def __init__(self, entry, editor, graph_factory):
        super().__init__(editor)
        self.editor = editor
        self.entry = entry
        self.generation = editor._document_generation
        self.setWindowTitle('状态与转换关系')
        self.resize(1140, 700)
        layout = QVBoxLayout(self)
        caption = QLabel(f'UI：{entry.findtext("title") or "(空名称)"}  [ID {entry.findtext("id") or "?"}]')
        caption.setTextFormat(Qt.PlainText)
        layout.addWidget(caption)
        layout.addWidget(QLabel('修改立即进入文档撤销栈；关闭窗口保留已应用修改。新增沿用选中状态的样式，不带转换；复制保留转换。'))
        splitter = QSplitter()
        layout.addWidget(splitter, 1)
        left = QWidget()
        left_layout = QVBoxLayout(left)
        left_layout.setContentsMargins(0, 0, 0, 0)
        self.states = QTreeWidget()
        self.states.setHeaderLabels(['状态名称', 'ID', '尺寸'])
        self.states.setColumnWidth(0, 150)
        self.states.setColumnWidth(1, 100)
        left_layout.addWidget(self.states)
        for actions in [[('新增…', lambda: self.add(False)), ('复制…', lambda: self.add(True))],
                        [('改名…', self.rename), ('删除…', self.delete)],
                        [('预览选中状态', self.preview)]]:
            row = QHBoxLayout()
            for title, callback in actions:
                button = QPushButton(title)
                if callback == self.delete:
                    destructive(button)
                button.clicked.connect(callback)
                row.addWidget(button)
            left_layout.addLayout(row)
        splitter.addWidget(left)
        tabs = QTabWidget()
        transition_panel = QWidget()
        transition_layout = QVBoxLayout(transition_panel)
        self.transitions = QTreeWidget()
        self.transitions.setHeaderLabels(['type', '目标状态', 'str1', 'int1', 'int2', 'str2', 'int3'])
        self.transitions.setColumnWidth(0, 50)
        self.transitions.setColumnWidth(1, 220)
        transition_layout.addWidget(self.transitions)
        row = QHBoxLayout()
        for title, callback in [('新增转换…', lambda: self.edit_transition(False)),
                                ('编辑转换…', lambda: self.edit_transition(True)),
                                ('删除转换', self.delete_transition)]:
            button = QPushButton(title)
            if title == '删除转换':
                destructive(button)
            button.clicked.connect(callback)
            row.addWidget(button)
        transition_layout.addLayout(row)
        tabs.addTab(transition_panel, '选中状态的转换')
        self.graph = graph_factory()
        tabs.addTab(self.graph, '状态关系图')
        splitter.addWidget(tabs)
        splitter.setSizes([360, 780])
        bar = QHBoxLayout()
        layout.addLayout(bar)
        self.undo_button = QPushButton('撤销')
        self.redo_button = QPushButton('重做')
        self.undo_button.setIcon(icon('undo'))
        self.redo_button.setIcon(icon('redo'))
        self.undo_button.clicked.connect(lambda: self.history(False))
        self.redo_button.clicked.connect(lambda: self.history(True))
        bar.addWidget(self.undo_button)
        bar.addWidget(self.redo_button)
        bar.addStretch(1)
        close = QPushButton('关闭')
        close.clicked.connect(self.accept)
        bar.addWidget(close)
        self.states.currentItemChanged.connect(self.load_transitions)
        self.transitions.itemDoubleClicked.connect(lambda: self.edit_transition(True))
        self.reload()

    def valid(self):
        return self.generation == self.editor._document_generation and belongs_to(self.editor.xml_root, self.entry)

    def current_state(self):
        row = self.states.currentItem()
        return row.data(0, Qt.UserRole) if row else None

    def reload(self, selected=None):
        if not self.valid():
            self.reject()
            return
        if selected is None:
            selected = self.current_state()
        self.states.clear()
        choice = None
        for state in own_states(self.entry):
            row = QTreeWidgetItem([state.findtext('title') or '(空名称)', state.findtext('id') or '',
                                  f'{state.findtext("width") or "0"} × {state.findtext("height") or "0"}'])
            row.setData(0, Qt.UserRole, state)
            row.setToolTip(0, state.findtext('title') or '(空名称)')
            self.states.addTopLevelItem(row)
            if state is selected:
                choice = row
        self.states.setCurrentItem(choice if choice is not None else self.states.topLevelItem(0))
        self.graph.load_states(self.entry)
        self.graph.scene.setSceneRect(self.graph.scene.itemsBoundingRect().adjusted(-40, -40, 40, 40))
        self.undo_button.setEnabled(bool(self.editor.command_stack._undo))
        self.redo_button.setEnabled(bool(self.editor.command_stack._redo))

    def load_transitions(self, *unused):
        self.transitions.clear()
        state = self.current_state()
        if state is None:
            return
        titles = {s.findtext('id'): state_caption(s) for s in own_states(self.entry)}
        for transition in state.findall('transitions/transition'):
            values = [transition.findtext(tag) or '' for tag in TRANSITION_FIELDS]
            values[1] = titles.get(values[1], f'失效引用：{values[1]}')
            row = QTreeWidgetItem(values)
            row.setData(0, Qt.UserRole, transition)
            for n, text in enumerate(values):
                row.setToolTip(n, text)
            self.transitions.addTopLevelItem(row)

    def run(self, action, selected=None):
        if not self.valid():
            self.reject()
            return
        try:
            result = action()
            self.reload(result if hasattr(result, 'tag') and result.tag == 'state' else selected)
        except (ValueError, TypeError) as error:
            QMessageBox.warning(self, '修改未应用', str(error))

    def add(self, duplicate):
        state = self.current_state()
        if state is None:
            return
        base = (state.findtext('title') or 'state') + ('_copy' if duplicate else '_new')
        title = base
        occupied = {s.findtext('title') for s in own_states(self.entry)}
        n = 2
        while title in occupied:
            title = f'{base}_{n}'
            n += 1
        title, ok = QInputDialog.getText(self, '复制状态' if duplicate else '新增状态', '新状态名称：', text=title)
        if ok:
            self.run(lambda: self.editor.add_document_state(state, title, keep_transitions=duplicate))

    def rename(self):
        state = self.current_state()
        if state is None:
            return
        title, ok = QInputDialog.getText(self, '状态改名', '状态名称：', text=state.findtext('title') or '')
        if ok:
            self.run(lambda: self.editor.rename_document_state(state, title), state)

    def delete(self):
        state = self.current_state()
        if state is None:
            return
        try:
            references = state_referrers(self.editor.xml_root, state)
        except ValueError as error:
            QMessageBox.warning(self, '无法删除', str(error))
            return
        if len(own_states(self.entry)) <= 1:
            QMessageBox.warning(self, '无法删除', '每个 UI 节点至少保留一个状态')
            return
        replacement = None
        if references:
            dialog = DeleteStateDialog(self.entry, state, references, self)
            if dialog.exec() != QDialog.Accepted:
                return
            replacement = dialog.replacement.currentData()
        elif QMessageBox.question(self, '删除状态', f'确认删除 {state_caption(state)}？\n脚本及未知引用需自行核对。') != QMessageBox.Yes:
            return
        self.run(lambda: self.editor.delete_document_state(state, replacement))

    def preview(self):
        state = self.current_state()
        if state is not None:
            self.run(lambda: self.editor.preview_document_state(state), state)

    def edit_transition(self, editing):
        state = self.current_state()
        if state is None:
            return
        row = self.transitions.currentItem()
        transition = row.data(0, Qt.UserRole) if editing and row else None
        if editing and transition is None:
            return
        dialog = TransitionDialog(self.entry, transition, self)
        if dialog.exec() == QDialog.Accepted:
            self.run(lambda: self.editor.set_document_transition(state, dialog.values(), transition), state)

    def delete_transition(self):
        state = self.current_state()
        row = self.transitions.currentItem()
        if state is None or row is None:
            return
        transition = row.data(0, Qt.UserRole)
        if QMessageBox.question(self, '删除转换', '确认删除选中的状态转换？') == QMessageBox.Yes:
            self.run(lambda: self.editor.delete_document_transition(state, transition), state)

    def history(self, redo):
        self.run(self.editor.redo if redo else self.editor.undo)
