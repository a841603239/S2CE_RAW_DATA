"""Navigation and editor-only layers, composed into the main window."""
from PySide6.QtCore import Qt, QSignalBlocker
from PySide6.QtGui import QAction, QBrush, QColor, QKeySequence
from PySide6.QtWidgets import QDockWidget, QGraphicsItem, QMenu

from .document import owner_entry, is_page_title, numeric_rule
from .navigation import SearchIndex, NodeViewState, belongs_to, settings_key
from .navigation_ui import SearchPanel, NavigationReport, NavigationTarget
from .theme import icon, color


class NavigationController:
    def _init_navigation(self):
        self.view_state = NodeViewState()
        self._search_index = None
        self._search_dirty = True
        self._inspected_xml = None
        self._show_all_pages = False
        self.search_panel = SearchPanel(self)
        self.search_dock = QDockWidget('节点搜索（全部页面）', self)
        self.search_dock.setObjectName('node_search')
        self.search_dock.setWidget(self.search_panel)
        self.addDockWidget(Qt.BottomDockWidgetArea, self.search_dock)
        self.search_dock.hide()
        menu = self.menuBar().addMenu('视图')
        self.search_action = QAction('搜索节点', self)
        self.search_action.setIcon(icon('search'))
        self.search_action.setShortcut(QKeySequence.Find)
        self.search_action.triggered.connect(self.show_search)
        menu.addAction(self.search_action)
        menu.addSeparator()
        self._layer_actions = []
        for title, callback in [
            ('锁定选中节点', lambda: self.set_nodes_locked(self.selected_entries(), True)),
            ('解锁选中节点', lambda: self.set_nodes_locked(self.selected_entries(), False)),
            ('隐藏选中节点', lambda: self.set_nodes_hidden(self.selected_entries(), True)),
            ('显示选中节点', lambda: self.set_nodes_hidden(self.selected_entries(), False)),
        ]:
            action = QAction(title, self)
            action.triggered.connect(lambda checked=False, callback=callback: callback())
            menu.addAction(action)
            self._layer_actions.append(action)
        menu.addSeparator()
        unlock_all = menu.addAction('全部解锁')
        unlock_all.triggered.connect(lambda: self.clear_node_state('locked'))
        show_all = menu.addAction('全部显示')
        show_all.triggered.connect(lambda: self.clear_node_state('hidden'))
        self.tree_widget.setContextMenuPolicy(Qt.CustomContextMenu)
        self.tree_widget.customContextMenuRequested.connect(self._tree_layer_menu)
        self.tree_widget.itemChanged.connect(self._layer_item_changed)

    def selected_entries(self):
        return [row.data(0, Qt.UserRole) for row in self.tree_widget.selectedItems()]

    def show_search(self):
        self.search_dock.show()
        self.search_dock.raise_()
        self.search_panel.query.setFocus()
        self.search_panel.query.selectAll()
        if self.search_panel.query.text():
            self.search_panel.run_search()

    def search_document(self, query, category='全部', exact=False):
        if not query.strip() or self.xml_root is None:
            return [], 0
        if self._search_dirty or self._search_index is None:
            self._search_index = SearchIndex(self.xml_root)
            self._search_dirty = False
        return self._search_index.search(query, category, exact)

    def invalidate_search(self):
        self._search_dirty = True
        if self.search_panel.query.text() and self.search_dock.isVisible():
            self.search_panel.schedule()
        else:
            self.search_panel.results.clear()

    def _restore_view_state(self):
        payload = self.settings.value(settings_key(self.xml_path), '') if self.xml_path else ''
        self.view_state.restore(self.xml_root, payload)

    def _store_view_state(self):
        if self.xml_path:
            self.settings.setValue(settings_key(self.xml_path), self.view_state.serialize())

    def _reset_navigation(self):
        self._search_index = None
        self._search_dirty = True
        self._inspected_xml = None
        self.search_panel.reset()
        for dialog in self.findChildren(NavigationReport):
            dialog.close()

    def _root_entries_for_view(self):
        if self.xml_root is None:
            return []
        panel = self._find_panel_entry()
        if panel is not None and self.current_page_title is not None:
            return [panel]
        return [self.xml_root] if self.xml_root.tag == 'uiEntry' else self.xml_root.findall('uiEntry')

    def is_geometry_locked(self, entry):
        return self.view_state.effective(entry, 'locked')

    def is_preview_hidden(self, entry):
        return self.view_state.effective(entry, 'hidden')

    def set_nodes_locked(self, entries, locked):
        self._set_node_state(entries, 'locked', locked)

    def set_nodes_hidden(self, entries, hidden):
        self._set_node_state(entries, 'hidden', hidden)

    def _set_node_state(self, entries, name, enabled):
        entries = [entry for entry in entries if belongs_to(self.xml_root, entry) and entry.tag == 'uiEntry']
        if not entries:
            return
        selection = self.selected_entries()
        self.cancel_active_gesture()
        values = getattr(self.view_state, name)
        values.update(entries) if enabled else values.difference_update(entries)
        self._apply_view_state(selection)
        self._store_view_state()

    def clear_node_state(self, name):
        selection = self.selected_entries()
        self.cancel_active_gesture()
        getattr(self.view_state, name).clear()
        self._apply_view_state(selection)
        self._store_view_state()

    def _sync_layer_row(self, entry, row):
        row.setCheckState(2, Qt.Checked if entry in self.view_state.locked else Qt.Unchecked)
        row.setCheckState(3, Qt.Checked if entry in self.view_state.hidden else Qt.Unchecked)
        for column, name in ((2, 'locked'), (3, 'hidden')):
            inherited = self.view_state.effective(entry, name) and entry not in getattr(self.view_state, name)
            row.setText(column, '继承' if inherited else '')
            row.setToolTip(column, '由祖先节点继承，请修改祖先节点的设置' if inherited else
                           ('仅保护画布拖动与缩放；XML 字段仍可编辑' if name == 'locked' else '仅影响编辑预览，不写入 XML'))
        row.setForeground(0, QBrush(color('disabled')) if self.is_preview_hidden(entry) else QBrush())

    def _apply_view_state(self, selection=None, notify=True):
        selection = self.selected_entries() if selection is None else selection
        with QSignalBlocker(self.canvas.scene), QSignalBlocker(self.tree_widget):
            for entry, item in self._scene_items.items():
                item.setVisible(not self.is_preview_hidden(entry))
                item.setFlag(QGraphicsItem.ItemIsMovable,
                             self.drag_enabled and not self.is_geometry_locked(entry))
                item.update()
            for entry, row in self._tree_items.items():
                self._sync_layer_row(entry, row)
            for entry in selection:
                item = self._scene_items.get(entry)
                if item is not None and item.isVisible():
                    item.setSelected(True)
        if notify:
            self._on_selection_count_changed(len(selection), entries=selection)
        self.canvas.viewport().update()

    def _layer_item_changed(self, row, column):
        if column not in (2, 3):
            return
        entry = row.data(0, Qt.UserRole)
        self._set_node_state([entry], 'locked' if column == 2 else 'hidden', row.checkState(column) == Qt.Checked)

    def _tree_layer_menu(self, position):
        row = self.tree_widget.itemAt(position)
        if row is None:
            return
        if not row.isSelected():
            self.tree_widget.clearSelection()
            row.setSelected(True)
        menu = QMenu(self)
        for action in self._layer_actions:
            menu.addAction(action)
        menu.exec(self.tree_widget.viewport().mapToGlobal(position))

    def navigate_to_element(self, element, attribute=None, generation=None):
        if ((generation is not None and generation != self._document_generation) or
                not belongs_to(self.xml_root, element)):
            self.statusBar().showMessage('定位目标已失效，请重新搜索或检查当前文档。')
            return False
        if not self.props.flush_pending_edits():
            return False
        self.cancel_active_gesture()
        if self._pending_refresh is not None:
            self.refresh_document(changes=[], selection=self.selected_entries())
        if not belongs_to(self.xml_root, element):
            return False
        entry = owner_entry(element)
        if entry is None:
            with QSignalBlocker(self.canvas.scene), QSignalBlocker(self.tree_widget):
                self.canvas.scene.clearSelection()
                self.tree_widget.clearSelection()
            self._current_scene_item = None
            inspected = element.getparent() if element.getparent() is not None else element
            self._inspected_xml = inspected
            self.props.show_xml_element(inspected, '全局 XML')
            for action in self._layer_actions:
                action.setEnabled(False)
        else:
            chain = [entry] + list(entry.iterancestors('uiEntry'))
            pages = {node.findtext('title') for node in chain if is_page_title(node.findtext('title'))}
            panel = self._find_panel_entry()
            page = next(iter(pages)) if len(pages) == 1 and (panel is None or panel in chain) else '(全部)'
            if self.page_combo.findText(page) < 0:
                page = '(全部)'
            if self.page_combo.currentText() != page:
                self.page_combo.setCurrentText(page)
            if entry not in self._scene_items:
                self.statusBar().showMessage('无法在当前层级显示目标节点。')
                return False
            self.view_state.hidden.difference_update(chain)
            self._apply_view_state([], notify=False)
            self._store_view_state()
            item = self._scene_items[entry]
            state = element if element.tag == 'state' else next(element.iterancestors('state'), None)
            if state is not None and owner_entry(state) is entry:
                item.current_state_title = state.findtext('title')
                self._preview_states[entry] = item.current_state_title
                item.refresh_from_xml(recursive=False)
            with QSignalBlocker(self.canvas.scene):
                self.canvas.scene.clearSelection()
                item.setSelected(True)
            self._on_selection_count_changed(1, entries=[entry])
            row = self._tree_items.get(entry)
            if row is not None:
                ancestor = row.parent()
                while ancestor is not None:
                    ancestor.setExpanded(True)
                    ancestor = ancestor.parent()
                with QSignalBlocker(self.tree_widget):
                    self.tree_widget.setCurrentItem(row)
                self.tree_widget.scrollToItem(row)
            self.canvas.ensureVisible(item)
        field = self.props.ensure_field_item(element, attribute)
        if field is not None:
            self.props.field_tree.setCurrentItem(field, 1)
            self.props.field_tree.scrollToItem(field)
        self.statusBar().showMessage('已定位：' + element.getroottree().getpath(element) +
                                     ('/@' + attribute if attribute else ''))
        return True

    def _show_navigation_report(self, title, summary, rows):
        dialog = NavigationReport(self, title, summary, rows)
        dialog.show()
        dialog.raise_()
        return dialog

    def _issue_target(self, issue):
        element, code, _, _ = issue
        attribute = 'num' if code in ('count', 'unknown-count') else None
        if code == 'value' and 'num' in element.attrib and numeric_rule(element) is None:
            attribute = 'num'
        if code in ('duplicate-id', 'identifier') and element.find('id') is not None:
            element = element.find('id')
        return NavigationTarget(element, attribute)
