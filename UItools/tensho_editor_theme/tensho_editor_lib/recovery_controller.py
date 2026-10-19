"""Periodic recovery, saved checkpoints and the save review workflow."""
import hashlib
import os
from pathlib import Path
import uuid
import zipfile

from lxml import etree
from PySide6.QtCore import Qt, QTimer, QSettings, QStandardPaths
from PySide6.QtWidgets import QApplication, QMessageBox, QDialog

from .changes import DocumentSnapshot, parse_xml
from .navigation import NodeViewState, settings_key
from .changes_ui import ChangesDialog
from .recovery import RecoveryStore, source_key, sha
from .recovery_ui import RecoveryDialog, RecoverySettingsDialog
from .theme import icon

_CURRENT_SOURCE = object()


def file_digest(path):
    if not os.path.exists(path):
        return None
    digest = hashlib.sha256()
    with open(path, 'rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


class RecoveryController:
    def _init_recovery(self):
        self._baseline = None
        self._base_disk_hash = None
        self._recovery_session = uuid.uuid4().hex
        self._last_recovery = None
        self._recovered_from = None
        self._recovery_error = ''
        self._startup_recovery_offered = False
        self.recovery_timer = QTimer(self)
        self.recovery_timer.timeout.connect(self.save_recovery_copy)
        menu = self.menuBar().addMenu('恢复与变更')
        for title, symbol, callback in [
            ('查看 XML 变更…', 'changes', self.show_document_changes),
            ('立即写入恢复副本', 'save', self.manual_recovery_copy),
            ('管理 / 恢复副本…', 'recovery', self.show_recovery_copies),
            ('恢复与变更设置…', 'settings', self.show_recovery_settings),
        ]:
            action = menu.addAction(title)
            action.setIcon(icon(symbol))
            action.triggered.connect(callback)

    def recovery_option(self, name, default):
        value = self.settings.value('recovery/' + name, default)
        return value if isinstance(value, bool) else str(value).lower() in ('true', '1', 'yes')

    def recovery_number(self, name, default, low, high):
        try:
            return max(low, min(high, int(self.settings.value('recovery/' + name, default))))
        except (ValueError, TypeError, OverflowError):
            return default

    def recovery_store(self):
        configured = self.settings.value('recovery/directory', '')
        if configured:
            directory = Path(str(configured))
        elif self.settings.format() == QSettings.IniFormat:
            # Independent settings files also isolate recovery storage (tests and portable setups).
            ini = Path(self.settings.fileName())
            directory = ini.parent / 'TenshoEditor-recovery' / source_key(str(ini))
        else:
            directory = Path(QStandardPaths.writableLocation(QStandardPaths.GenericDataLocation)) / 'TenshoEditor' / 'recovery'
        return RecoveryStore(directory)

    def configure_recovery_timer(self):
        self.recovery_timer.stop()
        if self.xml_tree is not None and self.recovery_option('enabled', True):
            self.recovery_timer.start(self.recovery_number('minutes', 1, 1, 60) * 60000)

    def _checkpoint_loaded(self, raw, baseline=None):
        self._baseline = baseline if baseline is not None else DocumentSnapshot(self.xml_tree)
        self._base_disk_hash = sha(raw)
        self._last_recovery = None
        self._recovered_from = None
        self.configure_recovery_timer()

    def _checkpoint_saved(self, payload, previous_path):
        self._retire_recovery(previous_path)
        self._baseline = DocumentSnapshot(self.xml_tree)
        self._base_disk_hash = sha(payload)
        self.configure_recovery_timer()

    def _retire_recovery(self, source=_CURRENT_SOURCE):
        try:
            store = self.recovery_store()
            store.clear(self.xml_path if source is _CURRENT_SOURCE else source, self._recovery_session)
            if self._recovered_from is not None:
                store.delete(self._recovered_from)
            self._last_recovery = None
            self._recovered_from = None
        except (OSError, ValueError) as error:
            self._recovery_error = '恢复副本清理失败：' + str(error)

    def cleanup_recovery_copies(self):
        try:
            self.recovery_store().cleanup(copies=self.recovery_number('copies', 10, 1, 20),
                days=self.recovery_number('days', 30, 1, 365))
            return True
        except (OSError, ValueError) as error:
            self._recovery_error = str(error)
            return False

    def save_recovery_copy(self, manual=False):
        if self.xml_tree is None or self._baseline is None:
            return None
        if not manual and (not self.recovery_option('enabled', True) or QApplication.activeModalWidget() is not None):
            return None
        if any(item._drag_context is not None or item._resizing for item in self._scene_items.values()):
            return None
        if not self.is_modified():
            self._retire_recovery()
            return None
        digest = self.document_fingerprint()
        try:
            if not manual and self._last_recovery is not None:
                previous_digest, record = self._last_recovery
                if previous_digest == digest and record.path.is_file():
                    return record
            record = self.recovery_store().write(self.xml_path, self._recovery_session,
                self.xml_tree, self._baseline, self._xml_declaration, self._base_disk_hash)
            self._last_recovery = digest, record
            if self.cleanup_recovery_copies():
                self._recovery_error = ''
            else:
                self.statusBar().showMessage('恢复副本已写入，但旧副本清理失败：' + self._recovery_error, 12000)
                return record
            self.statusBar().showMessage('已写入恢复副本；原 XML 尚未保存。', 6000)
            return record
        except (OSError, ValueError, etree.Error, zipfile.BadZipFile, RuntimeError) as error:
            self._recovery_error = str(error)
            self.statusBar().showMessage('恢复副本写入失败：' + str(error), 12000)
            if manual:
                QMessageBox.warning(self, '恢复副本未写入', str(error))
            return None

    def manual_recovery_copy(self):
        if self.xml_tree is not None and self.props.flush_pending_edits():
            return self.save_recovery_copy(manual=True)
        return None

    def restore_recovery_copy(self, path):
        try:
            record, tree, baseline = self.recovery_store().read(path)
        except (OSError, ValueError, KeyError, TypeError, etree.Error, zipfile.BadZipFile, RuntimeError) as error:
            QMessageBox.warning(self, '无法恢复副本', str(error))
            return False
        if not self.maybe_save_changes():
            return False
        self._activate_document(tree, record.source or None, etree.tostring(tree, encoding='utf-8'), baseline=baseline)
        self._baseline = baseline
        self._saved_fingerprint = hashlib.sha256(baseline.payload).digest()
        self._base_disk_hash = record.disk_hash
        self._xml_declaration = record.declaration
        self._recovered_from = record.path
        self._last_recovery = None
        self.update_undo_actions()
        self.statusBar().showMessage('已恢复副本；原文件未写入，请核对变更后手动保存。', 15000)
        return True

    def _restore_recovered_view_state(self, baseline):
        # Persisted locks/visibility refer to saved IDs, even after an unsaved ID rename.
        original = parse_xml(baseline.payload).getroot()
        saved = NodeViewState()
        payload = self.settings.value(settings_key(self.xml_path), '') if self.xml_path else ''
        saved.restore(original, payload)
        mapping = dict(zip(original.iter(), baseline.elements))
        live = set(self.xml_root.iter())
        self.view_state.saved_keys = {mapping[e]: key for e, key in saved.saved_keys.items() if mapping[e] in live}
        for name in ('locked', 'hidden'):
            setattr(self.view_state, name, {mapping[e] for e in getattr(saved, name) if mapping[e] in live})

    def offer_startup_recovery(self):
        if self._startup_recovery_offered or not self.recovery_option('startup', True):
            return
        self._startup_recovery_offered = True
        self.cleanup_recovery_copies()
        try:
            records, errors = self.recovery_store().scan()
            if records or errors:
                dialog = RecoveryDialog(self, startup=True)
                dialog.exec()
                dialog.deleteLater()
        except (OSError, ValueError) as error:
            self.statusBar().showMessage('无法检查恢复副本：' + str(error), 12000)

    def show_recovery_copies(self):
        dialog = RecoveryDialog(self)
        dialog.exec()
        dialog.deleteLater()

    def show_recovery_settings(self):
        dialog = RecoverySettingsDialog(self)
        dialog.exec()
        dialog.deleteLater()

    def document_changes(self):
        return self._baseline.changes(self.xml_tree) if self._baseline is not None and self.xml_tree is not None else []

    def show_document_changes(self):
        if self.xml_tree is None or not self.props.flush_pending_edits():
            return None
        self._flush_pending_refresh()
        dialog = ChangesDialog(self)
        dialog.setAttribute(Qt.WA_DeleteOnClose)
        dialog.show()
        return dialog

    def _review_save(self, path, payload):
        if not self.recovery_option('review', True):
            return True
        expected = file_digest(path)
        same_source = self.xml_path is not None and source_key(path) == source_key(self.xml_path)
        changed_target = expected is not None and (not same_source or expected != self._base_disk_hash)
        if not self.document_changes() and not changed_target:
            return True
        before = self.document_fingerprint()
        generation = self._document_generation
        disk_bytes = None
        notice = ''
        if changed_target:
            with open(path, 'rb') as stream:
                disk_bytes = stream.read()
            if sha(disk_bytes) != expected:
                raise OSError('目标文件在读取时变化，请重新核对后保存')
            notice = ('原文件已被其他程序修改。' if same_source else '另存为目标已存在。') + '请同时核对“目标文件当前内容 → 将写入的内容”页；确认保存将覆盖该目标。'
        dialog = ChangesDialog(self, destination=os.path.abspath(path), disk_bytes=disk_bytes,
            payload=payload if changed_target else None, notice=notice)
        try:
            if dialog.exec() != QDialog.Accepted:
                return False
            if generation != self._document_generation or before != self.document_fingerprint():
                raise ValueError('核对期间文档内容已变化，请重新保存并核对')
            if file_digest(path) != expected:
                raise OSError('核对期间目标文件已变化，本次未覆盖，请重新保存并核对')
            self.settings.setValue('recovery/review', dialog.review_next.isChecked())
            return True
        finally:
            dialog.deleteLater()
