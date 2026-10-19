"""Identity-preserving XML commands; independent of Qt views."""
from lxml import etree


class Command:
    def __init__(self, undo_func, redo_func, description=""):
        self.undo_func = undo_func
        self.redo_func = redo_func
        self.description = description


class CommandStack:
    def __init__(self, max_size=200):
        self._undo = []
        self._redo = []
        self.max_size = max_size

    def push(self, cmd):
        self._undo.append(cmd)
        if len(self._undo) > self.max_size:
            self._undo.pop(0)
        self._redo.clear()

    def undo(self):
        if not self._undo:
            return None
        cmd = self._undo[-1]
        cmd.undo_func()
        self._undo.pop()
        self._redo.append(cmd)
        return cmd

    def redo(self):
        if not self._redo:
            return None
        cmd = self._redo[-1]
        cmd.redo_func()
        self._redo.pop()
        self._undo.append(cmd)
        return cmd

    def clear(self):
        self._undo.clear()
        self._redo.clear()


def capture_element(element):
    """Keep XML identities stable; commands never hold graphics items."""
    text = element.text
    cdata = False
    if text is not None and isinstance(element.tag, str) and len(element) == 0:
        markup = etree.tostring(element, encoding='unicode', with_tail=False)
        cdata = markup.partition('>')[2].startswith('<![CDATA[')
    return text, element.tail, dict(element.attrib), tuple(element), cdata


def set_xml_text(element, text):
    old = capture_element(element)
    element.text = etree.CDATA(text) if old[4] else text


class XmlEditCommand:
    def __init__(self, changes, description, before_selection, after_selection):
        self.changes = changes
        self.description = description
        self.before_selection = list(before_selection)
        self.after_selection = list(after_selection)

    def _apply(self, index):
        for change in self.changes:
            element, state = change[0], change[index]
            current = capture_element(element)
            if current[0] != state[0] or current[4] != state[4]:
                element.text = etree.CDATA(state[0]) if state[4] else state[0]
            if current[1] != state[1]:
                element.tail = state[1]
            if current[2] != state[2]:
                element.attrib.clear()
                element.attrib.update(state[2])
            if current[3] != state[3]:
                element[:] = state[3]

    def undo_func(self):
        self._apply(1)

    def redo_func(self):
        self._apply(2)
