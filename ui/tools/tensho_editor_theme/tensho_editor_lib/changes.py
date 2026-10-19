"""Identity-based saved checkpoints and XML differences, including recovery rebinding."""
from dataclasses import dataclass
from lxml import etree

from .commands import capture_element
from .document import owner_entry


def parse_xml(payload):
    import io
    return etree.parse(io.BytesIO(payload), etree.XMLParser(remove_blank_text=False,
        strip_cdata=False, resolve_entities=False, load_dtd=False, no_network=True))


def element_label(element):
    entry = owner_entry(element)
    state = element if element.tag == 'state' else next(element.iterancestors('state'), None)
    label = (f'{entry.findtext("title") or "(空名称)"} [ID {entry.findtext("id") or "?"}]'
             if entry is not None else '全局 XML')
    if state is not None:
        label += f' / {state.findtext("title") or "(空状态名)"}'
    return label


@dataclass
class ChangeRecord:
    kind: str
    label: str
    path: str
    before: str
    after: str
    target: object
    attribute: object = None


class DocumentSnapshot:
    def __init__(self, tree):
        self.payload = etree.tostring(tree, encoding='utf-8')
        self.elements = list(tree.getroot().iter())
        self.positions = {element: n for n, element in enumerate(self.elements)}
        self.states = {e: capture_element(e) for e in self.elements}
        self.tags = {e: e.tag for e in self.elements}
        self.parents = {e: e.getparent() for e in self.elements}
        self.paths = {e: tree.getpath(e) for e in self.elements}
        self.labels = {e: element_label(e) for e in self.elements}
        self._fragments = None

    def identity_pairs(self, tree):
        positions = {element: n for n, element in enumerate(tree.getroot().iter())}
        return [[n, positions[element]] for n, element in enumerate(self.elements) if element in positions]

    def rebind(self, tree, pairs):
        """Restore the original element correspondence without guessing by names or IDs."""
        live = list(tree.getroot().iter())
        mapping = {}
        used = set()
        if not isinstance(pairs, list):
            raise ValueError('恢复副本的节点映射无效')
        for pair in pairs:
            if (not isinstance(pair, list) or len(pair) != 2 or
                    any(type(n) is not int for n in pair)):
                raise ValueError('恢复副本的节点映射无效')
            a, b = pair
            if not (0 <= a < len(self.elements) and 0 <= b < len(live)) or a in mapping or b in used:
                raise ValueError('恢复副本的节点映射越界或重复')
            if self.tags[self.elements[a]] != live[b].tag:
                raise ValueError('恢复副本的节点映射与 XML 不一致')
            mapping[a] = live[b]
            used.add(b)
        keys = {element: mapping.get(n, element) for n, element in enumerate(self.elements)}
        self.states = {keys[e]: (s[0], s[1], s[2], tuple(keys[c] for c in s[3]), s[4])
                       for e, s in self.states.items()}
        self.parents = {keys[e]: keys.get(parent) for e, parent in self.parents.items()}
        for name in ('tags', 'paths', 'labels'):
            setattr(self, name, {keys[e]: value for e, value in getattr(self, name).items()})
        self.elements = [keys[e] for e in self.elements]
        self.positions = {element: n for n, element in enumerate(self.elements)}
        return self

    def fragment(self, element):
        if self._fragments is None:
            self._fragments = list(parse_xml(self.payload).getroot().iter())
        n = self.positions[element]
        return etree.tostring(self._fragments[n], encoding='unicode', with_tail=False)

    def changes(self, tree):
        live = list(tree.getroot().iter())
        current = set(live)
        previous = set(self.elements)
        added, removed = current - previous, previous - current
        result = []

        def surviving_parent(element):
            parent = self.parents[element]
            while parent is not None and parent not in current:
                parent = self.parents.get(parent)
            return parent

        for element in self.elements:
            if element in removed:
                if self.parents[element] not in removed:
                    result.append(ChangeRecord('删除', self.labels[element], self.paths[element],
                        self.fragment(element), '', surviving_parent(element)))
                continue
            old = self.states[element]
            new = capture_element(element)
            path = tree.getpath(element)
            label = element_label(element)
            if self.tags[element] != element.tag:
                result.append(ChangeRecord('字段变化', label, path, str(self.tags[element]), str(element.tag), element))
            if old[0] != new[0] or old[4] != new[4]:
                before = old[0] or ''
                after = new[0] or ''
                if old[4] != new[4]:
                    before = ('CDATA: ' if old[4] else '文本: ') + before
                    after = ('CDATA: ' if new[4] else '文本: ') + after
                result.append(ChangeRecord('字段变化', label, path, before, after, element))
            if old[1] != new[1]:
                result.append(ChangeRecord('尾随文本', label, path + '/tail()', old[1] or '', new[1] or '', element))
            for attribute in sorted(set(old[2]) | set(new[2])):
                before = old[2].get(attribute)
                after = new[2].get(attribute)
                if before != after:
                    kind = '新增属性' if before is None else ('删除属性' if after is None else '字段变化')
                    result.append(ChangeRecord(kind, label, path + '/@' + attribute,
                        before if before is not None else '(不存在)',
                        after if after is not None else '(不存在)', element,
                        attribute if after is not None else None))
            if self.parents[element] is not element.getparent():
                result.append(ChangeRecord('移动', label, path, self.paths[element], path, element))
            elif tuple(c for c in old[3] if c in current and c.getparent() is element) != tuple(c for c in new[3] if c in previous and self.parents[c] is element):
                result.append(ChangeRecord('子节点顺序', label, path, '原有子节点顺序', '原有子节点顺序已变化', element))
        for element in live:
            if element in added and element.getparent() not in added:
                result.append(ChangeRecord('新增', element_label(element), tree.getpath(element), '',
                    etree.tostring(element, encoding='unicode', with_tail=False), element))
        return result
