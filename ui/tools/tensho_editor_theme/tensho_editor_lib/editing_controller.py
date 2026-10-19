"""State and batch operations composed into MainWindow's XML transaction API."""
from lxml import etree
from PySide6.QtWidgets import QMessageBox

from .commands import set_xml_text
from .document import owner_entry, sync_count
from .navigation import belongs_to
from .state_editing import (require_state, state_name, clone_state, deletion_targets,
                            transition_values, TRANSITION_FIELDS, write_patch)
from .state_ui import StateEditorDialog
from .batch_ui import BatchEditDialog
from .theme import icon


class EditingController:
    def _init_editing(self, graph_factory):
        self._state_graph_factory = graph_factory
        self._state_dialog = None
        menu = self.menuBar().addMenu('状态与批量编辑')
        action = menu.addAction('状态与转换关系…')
        action.setIcon(icon('state'))
        action.triggered.connect(self.show_state_editor)
        action = menu.addAction('批量修改字段…')
        action.setIcon(icon('batch'))
        action.triggered.connect(self.show_batch_editor)

    def _reset_navigation(self):
        if self._state_dialog is not None:
            self._state_dialog.reject()
        super()._reset_navigation()

    def _sync_state_previews(self, changes):
        # Keep a chosen preview state across its rename, including undo and redo.
        mappings = {}
        for element, before, after in changes or []:
            parent = element.getparent()
            if element.tag != 'title' or parent is None or parent.tag != 'state':
                continue
            entry = owner_entry(parent)
            if before[0] == after[0]:
                continue
            old = after[0] if element.text == before[0] else before[0]
            mappings.setdefault(entry, {})[old] = element.text or ''
        for entry, mapping in mappings.items():
            item = self._scene_items.get(entry)
            title = self._preview_states.get(entry, item.current_state_title if item is not None else None)
            if title in mapping:
                self._preview_states[entry] = mapping[title]
                if item is not None:
                    item.current_state_title = mapping[title]

    def _prepare_document_operation(self):
        if self.xml_root is None:
            raise ValueError('请先打开 XML 文档')
        if not self.props.flush_pending_edits():
            return False
        self._flush_pending_refresh()
        return True

    def show_state_editor(self):
        if self.xml_root is None or not self._prepare_document_operation():
            return
        entries = self.selected_entries()
        if len(entries) != 1:
            QMessageBox.information(self, '状态编辑', '请先选中一个 UI 节点')
            return
        dialog = StateEditorDialog(entries[0], self, self._state_graph_factory)
        self._state_dialog = dialog
        try:
            dialog.exec()
        finally:
            self._state_dialog = None
            dialog.deleteLater()

    def show_batch_editor(self):
        if self.xml_root is not None and self._prepare_document_operation():
            dialog = BatchEditDialog(self)
            dialog.exec()
            dialog.deleteLater()

    def add_document_state(self, source, title, keep_transitions=False):
        if not self._prepare_document_operation():
            return None
        require_state(self.xml_root, source)
        clone = clone_state(self.xml_root, source, title, keep_transitions)
        container = source.getparent()
        snapshot = self.begin_edit([container])
        container.insert(list(container).index(source) + 1, clone)
        if self.finish_edit(snapshot, '复制状态' if keep_transitions else '新增状态'):
            return clone
        return None

    def rename_document_state(self, state, title):
        if not self._prepare_document_operation():
            return False
        entry = require_state(self.xml_root, state)
        title = state_name(entry, title, exclude=state)
        field = state.find('title')
        if field is None:
            raise ValueError('状态缺少 title 字段，请先修复')
        snapshot = self.begin_edit([field])
        set_xml_text(field, title)
        return self.finish_edit(snapshot, '状态改名')

    def delete_document_state(self, state, replacement=None):
        if not self._prepare_document_operation():
            return False
        references = deletion_targets(self.xml_root, state, replacement)
        container = state.getparent()
        snapshot = self.begin_edit([container] + references)
        for reference in references:
            set_xml_text(reference, replacement.findtext('id'))
        container.remove(state)
        return self.finish_edit(snapshot, '删除状态并替换引用' if references else '删除状态')

    def preview_document_state(self, state):
        entry = require_state(self.xml_root, state)
        if not self.navigate_to_element(state):
            return False
        item = self._scene_items.get(entry)
        if item is not None:
            item.current_state_title = state.findtext('title') or ''
            self._preview_states[entry] = item.current_state_title
            item.refresh_from_xml(recursive=False)
            self.props.set_items([item])
        return True

    def set_document_transition(self, source, values, transition=None):
        if not self._prepare_document_operation():
            return False
        values = transition_values(self.xml_root, source, values)
        container = source.find('transitions')
        if len(source.findall('transitions')) > 1:
            raise ValueError('状态含多个 transitions 集合，请先修复')
        if transition is not None:
            if container is None or transition not in container.findall('transition'):
                raise ValueError('转换不属于选中状态或已失效')
            for tag in TRANSITION_FIELDS:
                fields = transition.findall(tag)
                if len(fields) > 1 or any(len(field) for field in fields):
                    raise ValueError('转换字段重复或含子节点，请先检查结构')
        snapshot = self.begin_edit([source])
        if container is None:
            container = etree.SubElement(source, 'transitions', num='0')
        if transition is None:
            transition = etree.SubElement(container, 'transition')
        for tag in TRANSITION_FIELDS:
            field = transition.find(tag)
            if field is None:
                field = etree.SubElement(transition, tag)
            set_xml_text(field, values[tag])
        sync_count(container)
        return self.finish_edit(snapshot, '编辑状态转换')

    def delete_document_transition(self, source, transition):
        if not self._prepare_document_operation():
            return False
        require_state(self.xml_root, source)
        container = source.find('transitions')
        if container is None or transition not in container.findall('transition'):
            raise ValueError('转换不属于选中状态或已失效')
        snapshot = self.begin_edit([container])
        container.remove(transition)
        return self.finish_edit(snapshot, '删除状态转换')

    def apply_batch_plan(self, plan):
        if not self._prepare_document_operation():
            return False
        plan.validate(self.xml_root)
        if not plan.patches:
            return True
        snapshot = self.begin_edit(list(dict.fromkeys(patch.parent for patch in plan.patches)), shallow=True)
        for patch in plan.patches:
            write_patch(patch)
        return self.finish_edit(snapshot, '批量修改字段')
