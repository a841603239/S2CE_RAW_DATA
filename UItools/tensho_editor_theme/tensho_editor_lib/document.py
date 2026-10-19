"""XML format rules, references, cloning and serialization; no Qt dependency."""
import copy
import math
import re
from lxml import etree


def get_first_state(ui_entry, state_title=None):
    states = ui_entry.find("states")
    if states is None:
        return None
    all_states = states.findall("state")
    if not all_states:
        return None
    if state_title:
        for s in all_states:
            if s.findtext("title") == state_title:
                return s
    return all_states[0]


def get_all_state_titles(ui_entry):
    states = ui_entry.find("states")
    if states is None:
        return []
    return [s.findtext("title") or "" for s in states.findall("state")]


def get_float(elem, tag, default=0.0):
    if elem is None:
        return default
    txt = elem.findtext(tag)
    if txt is None or txt.strip() == "":
        return default
    try:
        value = float(txt)
        return value if math.isfinite(value) and abs(value) <= MAX_GEOMETRY else default
    except (ValueError, OverflowError):
        return default


def get_int(elem, tag, default=0):
    try:
        value = float(elem.findtext(tag)) if elem is not None else default
        return int(value) if math.isfinite(value) else default
    except (ValueError, TypeError, OverflowError):
        return default


def is_page_title(title):
    """判断某个 title 是否是 page_N 形式的页面节点。"""
    if not title:
        return False
    return title.lower().startswith("page_")


COUNT_CHILD_TAGS = {
    'children': 'uiEntry', 'states': 'state', 'tgas': 'tga',
    'tgaUses': 'tgaUse', 'effects': 'effect', 'transitions': 'transition',
}


MAX_GEOMETRY = 1000000


REFERENCE_TAGS = {'uiEntryIDRef': 'uiEntry', 'stateIDRef': 'state', 'tgaIDRef': 'tga'}


DEFINITION_TAGS = ('uiEntry', 'state', 'tga')


def canonical_id(value):
    value = value or ''
    return (value.lstrip('0') or '0') if re.fullmatch(r'[0-9]+', value) else value


def owner_entry(element):
    while element is not None:
        if element.tag == 'uiEntry':
            return element
        element = element.getparent()
    return None


def identifier_kind(element):
    parent = element.getparent()
    if element.tag == 'id' and parent is not None and parent.tag in ('uiEntry', 'state', 'tga'):
        return parent.tag
    return None


def reference_kind(element):
    parent = element.getparent()
    if element.tag == 'id' and parent is not None and parent.tag == 'tgaUse':
        return 'tga'
    # In all 447 nonzero occurrences in the supplied S2TW/S2CE samples,
    # uiEntry/int4 refers to a state owned by that same uiEntry.
    if element.tag == 'int4' and parent is not None and parent.tag == 'uiEntry':
        return 'state'
    return REFERENCE_TAGS.get(element.tag)


def numeric_rule(element, attribute=None):
    tag = attribute if attribute is not None else element.tag
    if not isinstance(tag, str):
        return None
    if attribute == 'num':
        return 'int', 0, 2147483647
    if attribute is not None:
        return None
    if tag in ('xOff', 'yOff'):
        return 'float', -MAX_GEOMETRY, MAX_GEOMETRY
    if tag in ('width', 'height'):
        return 'float', 0, MAX_GEOMETRY
    if tag in ('redMultiply', 'greenMultiply', 'blueMultiply', 'alphaMultiply'):
        return 'int', 0, 255
    if tag == 'textAlphaMultiply':
        return 'int', -2147483648, 4294967295
    if tag == 'int4' and element.getparent() is not None and element.getparent().tag == 'uiEntry':
        return 'int', -1, 4294967295
    if tag == 'fontColor' or re.fullmatch(r'color\d+', tag):
        return 'int', -2147483648, 4294967295
    if re.fullmatch(r'(?:int|flag)\d+', tag):
        return 'int', -2147483648, 2147483647
    return None


def validate_scalar(element, text, attribute=None):
    rule = numeric_rule(element, attribute)
    label = '@' + attribute if attribute is not None else str(element.tag)
    if rule is not None:
        kind, low, high = rule
        stripped = text.strip()
        if kind == 'int':
            if not re.fullmatch(r'[+-]?[0-9]+', stripped):
                raise ValueError(f'{label} 必须是整数')
            value = int(stripped)
        else:
            if not re.fullmatch(r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?', stripped):
                raise ValueError(f'{label} 必须是有限的十进制数值')
            try:
                value = float(stripped)
            except ValueError:
                raise ValueError(f'{label} 必须是有限数值') from None
            if not math.isfinite(value):
                raise ValueError(f'{label} 不接受 NaN 或无穷大')
        if not low <= value <= high:
            raise ValueError(f'{label} 必须在 {low} 到 {high} 之间')
    if attribute is None and identifier_kind(element) is not None:
        normalized = canonical_id(text)
        if not re.fullmatch(r'[0-9]+', text) or len(normalized) > 10 or int(normalized) > 4294967295:
            raise ValueError('ID 必须是 0 到 4294967295 之间的十进制整数')
    # Ask lxml to validate XML 1.0 characters before touching the live document.
    probe = etree.Element('value')
    if attribute is None:
        probe.text = text
    else:
        probe.set(attribute, text)


class DocumentIndex:
    """One scan for global definitions and the exact state/texture collection scopes."""
    def __init__(self, root):
        self.root = root
        self.definitions = {kind: {} for kind in DEFINITION_TAGS}
        self.scoped = {}
        self.panel = None
        if root is None:
            return
        for element in root.iter(*DEFINITION_TAGS):
            kind = element.tag
            value = canonical_id(element.findtext('id'))
            self.definitions[kind].setdefault(value, []).append(element)
            if kind == 'uiEntry' and self.panel is None and element.findtext('title') == 'tensho_config_panel':
                self.panel = element
            parent = element.getparent()
            if parent is not None and parent.tag == {'state': 'states', 'tga': 'tgas'}.get(kind):
                scope = parent.getparent()
                self.scoped.setdefault((scope, kind, value), []).append(element)

    def resolve(self, reference, value=None):
        value = reference.text if value is None else value
        kind = reference_kind(reference)
        if kind is None or value in (None, '', '-1') or (reference.tag == 'int4' and value == '0'):
            return []
        value = canonical_id(value)
        if kind == 'uiEntry':
            return self.definitions[kind].get(value, [])
        entry = owner_entry(reference)
        if kind == 'state':
            return self.scoped.get((entry, kind, value), []) if entry is not None else []
        while entry is not None:
            matches = self.scoped.get((entry, kind, value), [])
            if matches:
                return matches
            entry = owner_entry(entry.getparent())
        return (self.scoped.get((self.root, kind, value), []) or
                self.definitions[kind].get(value, []))


def resolve_reference(root, reference, value=None, index=None):
    if index is not None:
        return index.resolve(reference, value)
    value = reference.text if value is None else value
    kind = reference_kind(reference)
    if kind is None or value is None or value == '' or value == '-1':
        return []
    if reference.tag == 'int4' and value == '0':
        return []
    value = canonical_id(value)
    if kind == 'uiEntry':
        return [e for e in root.iter('uiEntry') if canonical_id(e.findtext('id')) == value]
    if kind == 'state':
        entry = owner_entry(reference)
        return [] if entry is None else [e for e in entry.findall('states/state')
                                         if canonical_id(e.findtext('id')) == value]
    # Prefer the nearest owning tgas collection; support unambiguous global references.
    entry = owner_entry(reference)
    while entry is not None:
        matches = [e for e in entry.findall('tgas/tga') if canonical_id(e.findtext('id')) == value]
        if matches:
            return matches
        entry = owner_entry(entry.getparent())
    matches = [e for e in root.findall('tgas/tga') if canonical_id(e.findtext('id')) == value]
    if matches:
        return matches
    return [e for e in root.iter('tga') if canonical_id(e.findtext('id')) == value]


def count_children(container):
    child_tag = COUNT_CHILD_TAGS.get(container.tag)
    return len(container.findall(child_tag)) if child_tag else None


def sync_count(container):
    count = count_children(container)
    if count is not None:
        container.set('num', str(count))


def inspect_document(root):
    """Issues are keyed by XML identity, so insertions do not move the baseline."""
    issues = []
    if root is None:
        return issues
    index = DocumentIndex(root)

    def issue(element, code, message, severity='error'):
        issues.append((element, code, message, severity))

    groups = {}
    for element in root.iter():
        if not isinstance(element.tag, str):
            continue
        if element.tag in ('uiEntry', 'state', 'tga'):
            required = {'uiEntry': ('title', 'xOff', 'yOff', 'states'),
                        'state': ('title', 'width', 'height'), 'tga': ('path',)}[element.tag]
            for tag in required:
                if element.find(tag) is None:
                    issue(element, 'required-field', f'{element.tag} 缺少必需字段 {tag}')
            if element.tag == 'uiEntry' and not element.findall('states/state'):
                issue(element, 'required-state', 'UI 节点至少需要一个 state')
            ids = element.findall('id')
            if len(ids) != 1 or not (ids[0].text or '').strip():
                issue(element, 'identifier', f'{element.tag} 必须有一个非空 id')
            else:
                value = canonical_id(ids[0].text)
                groups.setdefault(value, []).append(element)
        if len(element) == 0:
            rule = numeric_rule(element)
            if rule is not None or identifier_kind(element) is not None:
                try:
                    validate_scalar(element, element.text or '')
                except ValueError as error:
                    issue(element, 'value', str(error))
        count = count_children(element)
        if count is not None and element.get('num') != str(count):
            issue(element, 'count', f'{element.tag}/@num 应为 {count}')
        for name, value in element.attrib.items():
            if name == 'num' and count is None:
                try:
                    validate_scalar(element, value, name)
                except ValueError as error:
                    issue(element, 'value', str(error))
                issue(element, 'unknown-count', f'{element.tag}/@num 的计数规则尚未定义', 'warning')
        kind = reference_kind(element)
        if kind is not None:
            value = element.text or ''
            if value in ('', '-1') and element.tag != 'id':
                continue
            if element.tag == 'int4' and value == '0':
                continue
            targets = index.resolve(element)
            if len(targets) != 1:
                reason = '不存在' if not targets else '不唯一'
                issue(element, 'reference', f'{element.tag} 引用的 {kind} ID {value!r} {reason}')
        elif re.search(r'IDRef$', element.tag, re.IGNORECASE):
            issue(element, 'unknown-reference', f'{element.tag} 的引用范围尚未定义，保留原值', 'warning')
        if element.tag in ('uiEntry', 'state', 'tga'):
            for tag in ('id', 'title', 'xOff', 'yOff', 'width', 'height', 'states', 'children', 'tgas'):
                if len(element.findall(tag)) > 1:
                    issue(element, 'duplicate-field', f'{element.tag} 下的 {tag} 不能重复')
    for value, elements in groups.items():
        if len(elements) > 1:
            for element in elements:
                issue(element, 'duplicate-id', f'定义 ID {value!r} 在文档内重复（UI、状态和贴图共用 ID 范围）')
    return issues


def format_issues(issues, limit=30):
    lines = []
    for element, _, message, severity in issues[:limit]:
        path = element.getroottree().getpath(element)
        lines.append(f"{'错误' if severity == 'error' else '待核对'}：{path}\n  {message}")
    if len(issues) > limit:
        lines.append(f'另有 {len(issues) - limit} 项未展开')
    return '\n'.join(lines)


class IdAllocator:
    """Keep the occupied set across a whole copy operation."""
    def __init__(self, root, reserved=None):
        values = [element.findtext('id') for element in root.iter(*DEFINITION_TAGS)]
        values.extend(reserved or ())
        self.used = {canonical_id(value) for value in values if value is not None}
        self.candidate = 1

    def allocate(self):
        while str(self.candidate) in self.used:
            self.candidate += 1
        if self.candidate > 4294967295:
            raise ValueError('没有可用的正整数 ID')
        value = str(self.candidate)
        self.used.add(value)
        self.candidate += 1
        return value


def allocate_id(root, kind='uiEntry', reserved=None):
    value = IdAllocator(root, reserved).allocate()
    if reserved is not None:
        reserved.add(value)
    return value


def clone_ui_entry(root, original):
    clone = copy.deepcopy(original)
    pairs = list(zip(original.iter(), clone.iter()))
    copied = dict(pairs)
    allocator = IdAllocator(root)
    source_index = DocumentIndex(original.getroottree().getroot())
    seen = set()
    for old, new in pairs:
        if old.tag in DEFINITION_TAGS:
            value = canonical_id(old.findtext('id'))
            if value in seen:
                raise ValueError('复制的子树中包含重复定义 ID，无法确定内部引用')
            seen.add(value)
            ident = new.find('id')
            if ident is None:
                ident = etree.SubElement(new, 'id')
            new_id = allocator.allocate()
            ident.text = new_id
    for old, new in pairs:
        kind = reference_kind(old)
        if kind is not None:
            # Resolve against the source tree before remapping copied definitions.
            targets = source_index.resolve(old)
            if len(targets) > 1:
                raise ValueError('ID 引用不唯一，无法安全复制')
            if targets and targets[0] in copied:
                new.text = copied[targets[0]].findtext('id')
    for element in clone.iter():
        sync_count(element)
    return clone


def expand_empty_elements(text):
    """Expand only real XML start tags; quoted text and special sections are opaque."""
    result = []
    cursor = 0
    while cursor < len(text):
        start = text.find('<', cursor)
        if start < 0:
            result.append(text[cursor:])
            break
        result.append(text[cursor:start])
        special = next(((prefix, end) for prefix, end in
                        (('<!--', '-->'), ('<![CDATA[', ']]>'), ('<?', '?>'))
                        if text.startswith(prefix, start)), None)
        if special is not None:
            end = text.find(special[1], start + len(special[0]))
            if end < 0:
                raise ValueError('XML 特殊区段未闭合')
            end += len(special[1])
        else:
            quote = None
            brackets = 0
            end = start + 1
            while end < len(text):
                char = text[end]
                if quote is not None:
                    if char == quote:
                        quote = None
                elif char in ('"', "'"):
                    quote = char
                elif text.startswith('<!--', end):
                    comment_end = text.find('-->', end + 4)
                    if comment_end < 0:
                        raise ValueError('XML 注释未闭合')
                    end = comment_end + 2
                elif char == '[':
                    brackets += 1
                elif char == ']':
                    brackets -= 1
                elif char == '>' and brackets == 0:
                    end += 1
                    break
                end += 1
            else:
                raise ValueError('XML 标记未闭合')
        token = text[start:end]
        if not token.startswith(('<!', '<?', '</')) and token.endswith('/>'):
            name = re.match(r'<([^\s/>]+)', token).group(1)
            token = token[:-2] + '></' + name + '>'
        result.append(token)
        cursor = end
    return ''.join(result)


def serialize_document(tree, declaration=False):
    raw = etree.tostring(tree, pretty_print=False, xml_declaration=declaration, encoding='utf-8')
    return expand_empty_elements(raw.decode('utf-8')).encode('utf-8')
