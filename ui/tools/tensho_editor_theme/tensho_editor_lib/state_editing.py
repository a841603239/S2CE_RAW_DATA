"""State editing rules and explicit batch field plans; independent of Qt."""
import copy
import hashlib
import re
from dataclasses import dataclass, field
from lxml import etree

from .commands import set_xml_text
from .document import (DocumentIndex, IdAllocator, DEFINITION_TAGS, owner_entry,
                       reference_kind, sync_count, validate_scalar, get_first_state, canonical_id)
from .navigation import belongs_to


TRANSITION_FIELDS = ('type', 'stateIDRef', 'str1', 'int1', 'int2', 'str2', 'int3')
COLOR_TAGS = ('redMultiply', 'greenMultiply', 'blueMultiply')
STATE_FIELDS = ('id', 'title', 'width', 'height', 'stateText', 'tooltip', 'int7', 'int8',
    'int9', 'int10', 'int11', 'flag7', 'localisationID', 'tooltipID', 'font', 'int12',
    'int13', 'textAlphaMultiply', 'fontColor', 'twui', 'int15', 'int16', 'int17',
    'flag8', 'flag9', 'flag10', 'normalt0', 'int18', 'int19', 'int20', 'int21',
    'stateDescription', 'eventText', 'tgaUses', 'int23', 'int24', 'transitions')


def own_states(entry):
    return entry.findall('states/state')


def require_state(root, state):
    entry = owner_entry(state)
    if (state.tag != 'state' or not belongs_to(root, state) or entry is None
            or state not in own_states(entry)):
        raise ValueError('状态不属于当前节点或已失效')
    return entry


def state_name(entry, title, exclude=None):
    title = title.strip()
    if not title:
        raise ValueError('状态名称不能为空')
    validate_scalar(etree.Element('title'), title)
    if any(s is not exclude and s.findtext('title') == title for s in own_states(entry)):
        raise ValueError('同一 UI 节点的状态名称不能重复')
    return title


def clone_state(root, source, title, keep_transitions=True):
    entry = require_state(root, source)
    title = state_name(entry, title)
    clone = copy.deepcopy(source)
    if len(source.findall('title')) != 1:
        raise ValueError('原状态必须有一个 title 字段')
    pairs = list(zip(source.iter(), clone.iter()))
    copied = dict(pairs)
    allocator = IdAllocator(root)
    index = DocumentIndex(root)
    for old, new in pairs:
        if old.tag in DEFINITION_TAGS:
            if old is not source:
                raise ValueError('状态内含嵌套定义，请先检查 XML 结构')
            ident = new.find('id')
            if ident is None:
                raise ValueError('原状态缺少 ID')
            ident.text = allocator.allocate()
    for old, new in pairs:
        if reference_kind(old) is not None:
            targets = index.resolve(old)
            if len(targets) > 1:
                raise ValueError('状态内的引用不唯一，无法安全复制')
            if targets and targets[0] in copied:
                new.text = copied[targets[0]].findtext('id')
    set_xml_text(clone.find('title'), title)
    if not keep_transitions:
        for container in clone.findall('transitions'):
            for transition in container.findall('transition'):
                container.remove(transition)
    for element in clone.iter():
        sync_count(element)
    return clone


def state_referrers(root, state):
    require_state(root, state)
    index = DocumentIndex(root)
    contained = set(state.iter())
    references = []
    for element in root.iter():
        if element in contained or reference_kind(element) != 'state':
            continue
        targets = index.resolve(element)
        if state in targets:
            if len(targets) != 1:
                raise ValueError('被删除状态的引用不唯一，请先修复 ID')
            references.append(element)
    return references


def deletion_targets(root, state, replacement=None):
    entry = require_state(root, state)
    remaining = [s for s in own_states(entry) if s is not state]
    if not remaining:
        raise ValueError('每个 UI 节点至少保留一个状态')
    if replacement is not None and replacement not in remaining:
        raise ValueError('替代目标必须是同一 UI 节点中的其他状态')
    references = state_referrers(root, state)
    if references and replacement is None:
        raise ValueError(f'该状态被 {len(references)} 个已知字段引用，请先指定替代状态')
    if (replacement is not None and canonical_id(replacement.findtext('id')) == '0'
            and any(ref.tag == 'int4' for ref in references)):
        raise ValueError('int4 将 0 视为空引用，不能替换为 ID 为 0 的状态')
    return references


def transition_values(root, source, values):
    entry = require_state(root, source)
    if set(values) != set(TRANSITION_FIELDS):
        raise ValueError('转换字段不完整')
    result = {tag: str(value) for tag, value in values.items()}
    matches = [s for s in own_states(entry) if s.findtext('id') == result['stateIDRef']]
    if len(matches) != 1:
        raise ValueError('转换目标必须是同一 UI 节点中的有效状态')
    for tag, value in result.items():
        if tag in ('type', 'int1', 'int2', 'int3'):
            if not re.fullmatch(r'[+-]?[0-9]+', value) or not -2147483648 <= int(value) <= 2147483647:
                raise ValueError(f'{tag} 必须是 32 位整数')
        validate_scalar(etree.Element(tag), value)
    return result


def fingerprint(root):
    return hashlib.sha256(etree.tostring(root)).digest()


@dataclass
class FieldPatch:
    parent: object
    tag: str
    element: object
    before: str
    after: str

    @property
    def label(self):
        entry = owner_entry(self.parent)
        state = self.parent if self.parent.tag == 'state' else next(self.parent.iterancestors('state'), None)
        path = f'{entry.findtext("title") or "(空名称)"} [ID {entry.findtext("id") or "?"}]' if entry is not None else '全局'
        if state is not None:
            path += f' / {state.findtext("title") or "(空状态名)"}'
        if self.parent.tag == 'tgaUse':
            path += f' / 贴图{self.parent.getparent().findall("tgaUse").index(self.parent) + 1}'
        return path


@dataclass
class BatchPlan:
    root: object
    baseline: bytes
    patches: list = field(default_factory=list)
    skipped: int = 0
    entry_count: int = 0
    state_count: int = 0

    def validate(self, root):
        if root is not self.root or fingerprint(root) != self.baseline:
            raise ValueError('文档已变化，批量预览已失效，请重新生成')
        seen = set()
        for patch in self.patches:
            key = (patch.parent, patch.tag)
            if key in seen or not belongs_to(root, patch.parent):
                raise ValueError('批量修改目标重复或已失效')
            seen.add(key)
            matches = patch.parent.findall(patch.tag)
            if patch.element is None:
                if matches:
                    raise ValueError('字段已新增，请重新生成预览')
            elif matches != [patch.element] or len(patch.element) or patch.element.text != patch.before:
                raise ValueError('字段内容已变化，请重新生成预览')
            validate_scalar(patch.element if patch.element is not None else etree.Element(patch.tag), patch.after)


def scoped_entries(root, selected, visible, scope):
    selected = [entry for entry in selected if belongs_to(root, entry) and entry.tag == 'uiEntry']
    if scope == 'selected':
        candidates = selected
    elif scope == 'descendants':
        candidates = [child for entry in selected for child in entry.iter('uiEntry')]
    elif scope == 'preview':
        candidates = list(visible)
    elif scope == 'document':
        candidates = list(root.iter('uiEntry'))
    else:
        raise ValueError('未知节点范围')
    wanted = set(candidates)
    return [entry for entry in root.iter('uiEntry') if entry in wanted]


def selected_states(entry, mode, name, previews):
    if mode == 'all':
        return own_states(entry)
    if mode == 'named':
        return [s for s in own_states(entry) if (s.findtext('title') or '') == name]
    if mode == 'preview':
        state = get_first_state(entry, previews.get(entry))
        return [state] if state is not None else []
    raise ValueError('未知状态范围')


def rgb_value(value):
    if not re.fullmatch(r'#[0-9a-fA-F]{6}', value):
        raise ValueError('贴图颜色请填写 #RRGGBB，例如 #80C0FF')
    return tuple(int(value[n:n + 2], 16) for n in (1, 3, 5))


def argb_value(value):
    if not re.fullmatch(r'#[0-9a-fA-F]{8}', value):
        raise ValueError('文字颜色请填写 #AARRGGBB，例如 #FFFFFFFF')
    packed = int(value[1:], 16)
    return str(packed - 4294967296 if packed >= 2147483648 else packed)


def rename_value(old, operation, value, find):
    if operation == 'prefix':
        return value + old
    if operation == 'suffix':
        return old + value
    if operation == 'replace':
        if not find:
            raise ValueError('查找文字不能为空')
        return old.replace(find, value)
    raise ValueError('未知名称修改方式')


def build_batch_plan(root, entries, previews, *, operation, value, state_mode='all',
                     state_title='', create_missing=False, rename_mode='prefix', find='', texture=None):
    entries = list(dict.fromkeys(entries))
    if not entries:
        raise ValueError('所选范围内没有 UI 节点')
    if any(not belongs_to(root, entry) or entry.tag != 'uiEntry' for entry in entries):
        raise ValueError('范围包含其他文档的节点')
    plan = BatchPlan(root, fingerprint(root), entry_count=len(entries))
    states = [state for entry in entries for state in selected_states(entry, state_mode, state_title, previews)]
    plan.state_count = len(states)

    def add(parent, tag, after):
        matches = parent.findall(tag)
        if len(matches) > 1:
            raise ValueError(f'{tag} 字段重复，无法批量修改')
        element = matches[0] if matches else None
        if element is not None and len(element):
            raise ValueError(f'{tag} 不是叶子字段')
        if element is None and not create_missing:
            plan.skipped += 1
            return
        before = element.text if element is not None else None
        validate_scalar(element if element is not None else etree.Element(tag), after)
        if before != after:
            plan.patches.append(FieldPatch(parent, tag, element, before, after))

    if operation in ('entry_name', 'state_name'):
        targets = entries if operation == 'entry_name' else states
        for target in targets:
            new = rename_value(target.findtext('title') or '', rename_mode, value, find)
            if not new.strip():
                raise ValueError('批量修改后的名称不能为空')
            add(target, 'title', new)
        if operation == 'state_name':
            changed = {patch.parent: patch.after for patch in plan.patches}
            for entry in entries:
                names = [changed.get(s, s.findtext('title') or '') for s in own_states(entry)]
                # Existing duplicate titles may be inspected, but do not introduce more collisions.
                for state in own_states(entry):
                    if state in changed and names.count(changed[state]) > 1:
                        raise ValueError('批量修改后同一 UI 节点的状态名称重复')
    elif operation == 'font':
        if not value.strip():
            raise ValueError('字体不能为空，例如 bardi_10, Normal')
        for state in states:
            add(state, 'font', value)
    elif operation in ('fontColor', 'textAlphaMultiply'):
        color = argb_value(value)
        for state in states:
            add(state, operation, color)
    elif operation in ('tint', 'opacity', 'texture'):
        if operation == 'tint':
            values = dict(zip(COLOR_TAGS, map(str, rgb_value(value))))
        elif operation == 'opacity':
            if not re.fullmatch(r'[0-9]+', value) or not 0 <= int(value) <= 255:
                raise ValueError('贴图透明度必须是 0 到 255 的整数')
            values = {'alphaMultiply': str(int(value))}
        else:
            if texture is None or not belongs_to(root, texture) or texture.tag != 'tga':
                raise ValueError('请选择当前文档的目标贴图定义')
            values = {'id': texture.findtext('id') or ''}
        index = DocumentIndex(root)
        for state in states:
            uses = state.findall('tgaUses/tgaUse')
            if not uses:
                plan.skipped += 1
            for use in uses:
                if operation == 'texture':
                    ref = use.find('id')
                    if ref is None or index.resolve(ref, values['id']) != [texture]:
                        raise ValueError('目标贴图在某个使用位置无法唯一解析，请检查贴图作用域')
                for tag, after in values.items():
                    add(use, tag, after)
    else:
        raise ValueError('未知批量操作')
    plan.validate(root)
    return plan


def write_patch(patch):
    element = patch.element
    if element is None:
        element = etree.Element(patch.tag)
        # Keep image channel fields adjacent to dimensions and ahead of flags.
        if patch.parent.tag == 'tgaUse' and patch.tag in COLOR_TAGS + ('alphaMultiply',):
            order = ('id', 'xOff', 'yOff', 'width', 'height', 'blueMultiply',
                     'greenMultiply', 'redMultiply', 'alphaMultiply')
            rank = order.index(patch.tag)
            position = next((n for n, child in enumerate(patch.parent)
                             if child.tag not in order or order.index(child.tag) > rank), len(patch.parent))
            patch.parent.insert(position, element)
        elif patch.parent.tag == 'state' and patch.tag in STATE_FIELDS:
            rank = STATE_FIELDS.index(patch.tag)
            position = next((n for n, child in enumerate(patch.parent)
                if child.tag in STATE_FIELDS and STATE_FIELDS.index(child.tag) > rank), len(patch.parent))
            patch.parent.insert(position, element)
        else:
            patch.parent.append(element)
    set_xml_text(element, patch.after)
