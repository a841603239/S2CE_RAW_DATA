"""Search results and clickable checks, with targets kept as XML identities."""
from dataclasses import dataclass

from PySide6.QtCore import Qt, QTimer
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLineEdit, QComboBox, QCheckBox,
    QLabel, QPushButton, QTreeWidget, QTreeWidgetItem, QDialog, QTextEdit,
    QDialogButtonBox, QAbstractItemView,
)

@dataclass
class NavigationTarget:
    element: object
    attribute: object = None


class SearchPanel(QWidget):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor
        layout = QVBoxLayout(self)
        controls = QHBoxLayout()
        self.query = QLineEdit()
        self.query.setPlaceholderText('搜索全部页面：名称、ID、文本或贴图路径')
        self.category = QComboBox()
        self.category.addItems(['全部', '名称', 'ID', '文本', '贴图路径'])
        self.exact = QCheckBox('完全匹配')
        button = QPushButton('搜索')
        controls.addWidget(self.query, 1)
        controls.addWidget(self.category)
        controls.addWidget(self.exact)
        controls.addWidget(button)
        layout.addLayout(controls)
        self.status = QLabel('输入关键词；点击结果定位。文本搜索包含脚本原文。')
        layout.addWidget(self.status)
        self.results = QTreeWidget()
        self.results.setHeaderLabels(['节点', 'ID', '匹配字段', '内容', 'XML 位置'])
        self.results.setRootIsDecorated(False)
        self.results.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.results.setColumnWidth(0, 180)
        self.results.setColumnWidth(2, 130)
        self.results.setColumnWidth(3, 260)
        layout.addWidget(self.results)
        self.timer = QTimer(self)
        self.timer.setSingleShot(True)
        self.timer.setInterval(150)
        self.timer.timeout.connect(self.run_search)
        self.query.textChanged.connect(self.schedule)
        self.category.currentTextChanged.connect(self.schedule)
        self.exact.toggled.connect(self.schedule)
        self.query.returnPressed.connect(self.run_search)
        button.clicked.connect(self.run_search)
        self.results.itemClicked.connect(self.activate_result)
        self.results.itemActivated.connect(self.activate_result)

    def schedule(self, *args):
        self.timer.start()

    def reset(self):
        self.timer.stop()
        self.results.clear()
        self.status.setText('输入关键词；点击结果定位。文本搜索包含脚本原文。')

    def run_search(self):
        self.timer.stop()
        records, total = self.editor.search_document(self.query.text(), self.category.currentText(), self.exact.isChecked())
        self.results.clear()
        generation = self.editor._document_generation
        for record in records:
            entry = record.entry
            label = entry.findtext('title') or '(未命名)' if entry is not None else '全局 XML'
            ident = entry.findtext('id') or '' if entry is not None else ''
            value = record.value.replace('\n', ' ').replace('\r', ' ')
            match = value.casefold().find(self.query.text().strip().casefold())
            start = max(0, match - 35)
            snippet = ('…' if start else '') + value[start:start + 180]
            row = QTreeWidgetItem([label, ident, record.category + ' / ' + record.element.tag,
                                   snippet, record.element.getroottree().getpath(record.element)])
            row.setData(0, Qt.UserRole, (NavigationTarget(record.element), generation))
            self.results.addTopLevelItem(row)
        self.status.setText(f'共 {total} 项匹配，显示前 {len(records)} 项；点击结果定位。' if total else '没有匹配结果。')

    def activate_result(self, row, column=0):
        target, generation = row.data(0, Qt.UserRole)
        self.editor.navigate_to_element(target.element, target.attribute, generation)


class NavigationReport(QDialog):
    """Modeless so the located canvas and field editors remain immediately usable."""
    def __init__(self, editor, title, summary, rows):
        super().__init__(editor)
        self.editor = editor
        self.generation = editor._document_generation
        self.setWindowTitle(title)
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.resize(920, 640)
        layout = QVBoxLayout(self)
        self.summary = QTextEdit()
        self.summary.setReadOnly(True)
        self.summary.setPlainText(summary)
        layout.addWidget(self.summary, 1)
        self.results = QTreeWidget()
        self.results.setHeaderLabels(['类型', '说明（点击定位）', 'XML 位置'])
        self.results.setRootIsDecorated(False)
        self.results.setColumnWidth(0, 85)
        self.results.setColumnWidth(1, 440)
        for label, message, target in rows:
            path = target.element.getroottree().getpath(target.element)
            if target.attribute is not None:
                path += '/@' + target.attribute
            row = QTreeWidgetItem([label, message, path])
            row.setData(0, Qt.UserRole, target)
            self.results.addTopLevelItem(row)
        layout.addWidget(self.results, 2)
        self.results.itemClicked.connect(self.locate)
        self.results.itemActivated.connect(self.locate)
        buttons = QDialogButtonBox(QDialogButtonBox.Close)
        locate = buttons.addButton('定位选中项', QDialogButtonBox.ActionRole)
        locate.clicked.connect(self.locate_current)
        buttons.rejected.connect(self.close)
        layout.addWidget(buttons)

    def locate_current(self):
        row = self.results.currentItem()
        if row is not None:
            self.locate(row)

    def locate(self, row, column=0):
        target = row.data(0, Qt.UserRole)
        return self.editor.navigate_to_element(target.element, target.attribute, self.generation)
