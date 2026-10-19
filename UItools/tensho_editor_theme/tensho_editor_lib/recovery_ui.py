"""Recovery selection and preferences; originals remain untouched until normal save."""
from PySide6.QtCore import Qt, QDateTime, QTimeZone
from PySide6.QtWidgets import (QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel,
    QTreeWidget, QTreeWidgetItem, QPushButton, QMessageBox, QDialogButtonBox, QSpinBox, QCheckBox)
from .theme import icon, primary, destructive


class RecoveryDialog(QDialog):
    def __init__(self, editor, startup=False):
        super().__init__(editor)
        self.editor = editor
        self.store = editor.recovery_store()
        self.setWindowTitle('发现可恢复的 XML 副本' if startup else '恢复副本管理')
        self.resize(1000, 560)
        layout = QVBoxLayout(self)
        note = QLabel('恢复会打开副本中的编辑内容，并保留未保存标记；只有正常保存才写入原 XML。稍后处理会保留副本。')
        note.setWordWrap(True)
        layout.addWidget(note)
        self.results = QTreeWidget()
        self.results.setHeaderLabels(['原文件', '副本时间（香港时间）', '状态'])
        self.results.setColumnWidth(0, 540)
        self.results.setColumnWidth(1, 190)
        layout.addWidget(self.results, 1)
        self.status = QLabel()
        self.status.setTextFormat(Qt.PlainText)
        self.status.setWordWrap(True)
        layout.addWidget(self.status)
        directory = QLabel('副本目录：' + str(self.store.directory))
        directory.setTextFormat(Qt.PlainText)
        directory.setWordWrap(True)
        layout.addWidget(directory)
        bar = QHBoxLayout()
        layout.addLayout(bar)
        self.restore_button = QPushButton('恢复选中副本')
        primary(self.restore_button)
        self.restore_button.setIcon(icon('recovery', 'surface'))
        self.restore_button.clicked.connect(self.restore)
        bar.addWidget(self.restore_button)
        remove = QPushButton('删除选中副本')
        remove.setAutoDefault(False)
        destructive(remove)
        remove.setIcon(icon('delete', 'danger'))
        remove.clicked.connect(self.remove)
        bar.addWidget(remove)
        refresh = QPushButton('刷新列表')
        refresh.setAutoDefault(False)
        refresh.setIcon(icon('refresh'))
        refresh.clicked.connect(self.reload)
        bar.addWidget(refresh)
        bar.addStretch(1)
        close = QPushButton('稍后处理' if startup else '关闭')
        close.setAutoDefault(False)
        close.clicked.connect(self.reject)
        bar.addWidget(close)
        self.results.currentItemChanged.connect(self.selected)
        self.results.itemDoubleClicked.connect(lambda: self.restore())
        self.reload()

    def reload(self):
        self.results.clear()
        try:
            records, errors = self.store.scan()
            for record in records:
                timestamp = QDateTime.fromSecsSinceEpoch(int(record.created)).toTimeZone(QTimeZone(b'Asia/Hong_Kong')).toString('yyyy-MM-dd HH:mm:ss')
                row = QTreeWidgetItem([record.source or '(未命名 XML)', timestamp, '可尝试恢复'])
                row.setData(0, Qt.UserRole, record)
                row.setData(0, Qt.UserRole + 1, record.path)
                row.setToolTip(0, record.source)
                self.results.addTopLevelItem(row)
            for path, error in errors:
                row = QTreeWidgetItem([path.name, '', '副本损坏：' + error])
                row.setData(0, Qt.UserRole + 1, path)
                row.setToolTip(2, error)
                self.results.addTopLevelItem(row)
            self.status.setText(f'{len(records)} 份副本，{len(errors)} 份无法读取；恢复时会再次校验内容。')
            self.results.setCurrentItem(self.results.topLevelItem(0))
        except OSError as error:
            self.status.setText('无法读取恢复目录：' + str(error))
        self.selected()

    def selected(self, *unused):
        row = self.results.currentItem()
        self.restore_button.setEnabled(row is not None and row.data(0, Qt.UserRole) is not None)

    def restore(self):
        row = self.results.currentItem()
        record = row.data(0, Qt.UserRole) if row is not None else None
        if record is None:
            return
        if self.editor.restore_recovery_copy(record.path):
            self.accept()

    def remove(self):
        row = self.results.currentItem()
        path = row.data(0, Qt.UserRole + 1) if row is not None else None
        if path is None:
            return
        if QMessageBox.question(self, '删除恢复副本', '确认删除这份恢复副本？原 XML 不受影响。') != QMessageBox.Yes:
            return
        try:
            self.store.delete(path)
            self.reload()
        except (OSError, ValueError) as error:
            QMessageBox.warning(self, '无法删除副本', str(error))


class RecoverySettingsDialog(QDialog):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor
        self.setWindowTitle('恢复与变更设置')
        self.resize(570, 360)
        layout = QVBoxLayout(self)
        self.enabled = QCheckBox('启用定时恢复副本（原 XML 仍需手动保存）')
        self.enabled.setChecked(editor.recovery_option('enabled', True))
        layout.addWidget(self.enabled)
        form = QFormLayout()
        layout.addLayout(form)
        self.minutes = QSpinBox()
        self.minutes.setRange(1, 60)
        self.minutes.setValue(editor.recovery_number('minutes', 1, 1, 60))
        self.minutes.setSuffix(' 分钟')
        form.addRow('写入间隔', self.minutes)
        self.copies = QSpinBox()
        self.copies.setRange(1, 20)
        self.copies.setValue(editor.recovery_number('copies', 10, 1, 20))
        form.addRow('每份原文件最多保留', self.copies)
        self.days = QSpinBox()
        self.days.setRange(1, 365)
        self.days.setValue(editor.recovery_number('days', 30, 1, 365))
        self.days.setSuffix(' 天')
        form.addRow('副本保留期限', self.days)
        self.startup = QCheckBox('启动时检查可恢复副本')
        self.startup.setChecked(editor.recovery_option('startup', True))
        layout.addWidget(self.startup)
        self.review = QCheckBox('保存前显示 XML 变更核对')
        self.review.setChecked(editor.recovery_option('review', True))
        layout.addWidget(self.review)
        note = QLabel('仅为有修改的文档生成副本；相同内容不重复写入。超过份数或期限的副本会自动清理，整个目录最多保留 100 份。')
        note.setWordWrap(True)
        layout.addWidget(note)
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.button(QDialogButtonBox.Ok).setText('应用设置')
        buttons.button(QDialogButtonBox.Cancel).setText('取消')
        buttons.accepted.connect(self.apply)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def apply(self):
        for key, value in [('enabled', self.enabled.isChecked()), ('minutes', self.minutes.value()),
                           ('copies', self.copies.value()), ('days', self.days.value()),
                           ('startup', self.startup.isChecked()), ('review', self.review.isChecked())]:
            self.editor.settings.setValue('recovery/' + key, value)
        self.editor.configure_recovery_timer()
        self.editor.cleanup_recovery_copies()
        self.accept()
