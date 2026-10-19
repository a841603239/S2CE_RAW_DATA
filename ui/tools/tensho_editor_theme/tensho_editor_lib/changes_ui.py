"""Read-only saved XML differences, with optional save confirmation."""
from collections import Counter
import difflib
import itertools
from PySide6.QtCore import Qt
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QLabel, QTreeWidget,
    QTreeWidgetItem, QPushButton, QPlainTextEdit, QSplitter, QWidget, QTabWidget, QCheckBox)
from .theme import icon, primary, code_font


class ChangesDialog(QDialog):
    def __init__(self, editor, *, destination=None, disk_bytes=None, payload=None, notice=''):
        super().__init__(editor)
        self.editor = editor
        self.destination = destination
        self.generation = editor._document_generation
        self.fingerprint = None
        self.records = []
        self.setWindowTitle('保存前核对 XML 变更' if destination else '与打开 / 上次保存版本比较')
        self.resize(1120, 740)
        layout = QVBoxLayout(self)
        label = QLabel(('保存目标：' + str(destination)) if destination else '对照版本：打开文件时，或最近一次成功保存后的 XML。')
        label.setTextFormat(Qt.PlainText)
        label.setWordWrap(True)
        layout.addWidget(label)
        note = QLabel(notice or '新增 / 删除按整个子树显示；删除项定位到仍存在的最近父节点。悬停查看完整路径，选中后可查看原文。')
        note.setTextFormat(Qt.PlainText)
        note.setWordWrap(True)
        layout.addWidget(note)
        tabs = QTabWidget()
        layout.addWidget(tabs, 1)
        splitter = QSplitter(Qt.Vertical)
        self.results = QTreeWidget()
        self.results.setHeaderLabels(['类型', '节点 / 状态', '字段 / 位置', '原值', '新值'])
        for n, width in enumerate((90, 270, 240, 220, 220)):
            self.results.setColumnWidth(n, width)
        splitter.addWidget(self.results)
        detail = QWidget()
        detail_layout = QHBoxLayout(detail)
        self.before = QPlainTextEdit()
        self.after = QPlainTextEdit()
        self.before.setFont(code_font())
        self.after.setFont(code_font())
        self.before.setReadOnly(True)
        self.after.setReadOnly(True)
        self.before.setPlaceholderText('原内容（打开 / 上次保存时）')
        self.after.setPlaceholderText('当前内容')
        for caption, widget in [('原内容（打开 / 上次保存时）', self.before), ('当前内容', self.after)]:
            column = QVBoxLayout()
            column.addWidget(QLabel(caption))
            column.addWidget(widget)
            detail_layout.addLayout(column)
        splitter.addWidget(detail)
        splitter.setSizes([420, 210])
        tabs.addTab(splitter, '文档变更')
        if disk_bytes is not None and payload is not None:
            text = QPlainTextEdit()
            text.setReadOnly(True)
            diff = difflib.unified_diff(disk_bytes.decode('utf-8', errors='replace').splitlines(),
                payload.decode('utf-8', errors='replace').splitlines(), fromfile='目标文件当前内容', tofile='将写入的内容', lineterm='')
            text.setPlainText('目标文件文本差异（最多 5000 行 / 250000 字符；仅供核对）\n' +
                              '\n'.join(itertools.islice(diff, 5000))[:250000])
            tabs.addTab(text, '目标文件当前内容 → 将写入的内容')
        self.status = QLabel()
        self.status.setWordWrap(True)
        layout.addWidget(self.status)
        self.review_next = QCheckBox('以后保存前仍显示变更核对')
        self.review_next.setChecked(True)
        self.review_next.setVisible(destination is not None)
        layout.addWidget(self.review_next)
        bar = QHBoxLayout()
        layout.addLayout(bar)
        locate = QPushButton('定位选中项')
        locate.setAutoDefault(False)
        locate.setIcon(icon('locate'))
        locate.clicked.connect(self.locate_current)
        bar.addWidget(locate)
        refresh = QPushButton('刷新变更')
        refresh.setAutoDefault(False)
        refresh.setIcon(icon('refresh'))
        refresh.setVisible(destination is None)
        refresh.clicked.connect(self.reload)
        bar.addWidget(refresh)
        bar.addStretch(1)
        if destination is not None:
            save = QPushButton('确认保存')
            primary(save)
            save.setIcon(icon('save', 'surface'))
            save.clicked.connect(self.accept)
            bar.addWidget(save)
        close = QPushButton('取消保存' if destination else '关闭')
        close.setAutoDefault(False)
        close.clicked.connect(self.reject)
        bar.addWidget(close)
        self.results.currentItemChanged.connect(self.show_details)
        self.results.itemDoubleClicked.connect(lambda: self.locate_current())
        self.reload()
        if len(tabs.findChildren(QPlainTextEdit)) > 2 and not self.records:
            tabs.setCurrentIndex(1)

    def reload(self):
        if self.generation != self.editor._document_generation or self.editor.xml_tree is None:
            self.results.clear()
            self.status.setText('文档已切换，请重新打开变更核对')
            return
        self.records = self.editor.document_changes()
        self.fingerprint = self.editor.document_fingerprint()
        self.results.clear()
        for record in self.records[:2000]:
            field = record.path.rsplit('/', 1)[-1]
            row = QTreeWidgetItem([record.kind, record.label, field,
                record.before.replace('\n', ' ')[:180], record.after.replace('\n', ' ')[:180]])
            row.setData(0, Qt.UserRole, record)
            row.setToolTip(2, record.path)
            self.results.addTopLevelItem(row)
        counts = Counter(record.kind for record in self.records)
        summary = '；'.join(f'{kind} {count}' for kind, count in counts.items())
        self.status.setText((f'共 {len(self.records)} 项：' + summary if self.records else '文档与对照版本没有内容变化。') +
            ('；列表显示前 2000 项，可缩小修改批次核对。' if len(self.records) > 2000 else ''))
        self.results.setCurrentItem(self.results.topLevelItem(0))

    def show_details(self, *unused):
        row = self.results.currentItem()
        record = row.data(0, Qt.UserRole) if row is not None else None
        for widget, text in ((self.before, record.before if record else ''), (self.after, record.after if record else '')):
            widget.setPlainText(text[:100000] + ('\n（内容过长，仅显示前 100000 字符）' if len(text) > 100000 else ''))

    def locate_current(self):
        row = self.results.currentItem()
        if row is None:
            return False
        if self.generation != self.editor._document_generation or self.fingerprint != self.editor.document_fingerprint():
            self.status.setText('文档已变化，旧变更列表已失效，请刷新或重新打开')
            return False
        record = row.data(0, Qt.UserRole)
        if record.target is None:
            self.status.setText('该项没有可定位的当前节点，请查看原内容')
            return False
        return self.editor.navigate_to_element(record.target, record.attribute, self.generation)
