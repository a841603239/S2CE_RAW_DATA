"""Resource usages, path plans and portable component templates (no Qt)."""
import copy
import os
import re
from dataclasses import dataclass, field
from lxml import etree

from .document import (DocumentIndex, reference_kind, DEFINITION_TAGS,
                       IdAllocator, clone_ui_entry, sync_count, inspect_document,
                       validate_scalar)


@dataclass
class ResourceRecord:
    definition: object
    path_element: object
    path: str
    usages: list = field(default_factory=list)


def resource_records(root):
    index = DocumentIndex(root)
    records = [ResourceRecord(tga, tga.find('path'), tga.findtext('path') or '')
               for tga in root.iter('tga')]
    by_definition = {record.definition: record for record in records}
    for reference in root.iter():
        if reference_kind(reference) == 'tga':
            for target in index.resolve(reference):
                if target in by_definition:
                    by_definition[target].usages.append(reference)
    return records


def normalize_path(value):
    value = value.strip().replace('\\', '/')
    if not value:
        raise ValueError('贴图路径不能为空')
    validate_scalar(etree.Element('path'), value)
    return value


def prefix_plan(root, old_prefix, new_prefix):
    old = normalize_path(old_prefix).rstrip('/')
    if not old:
        raise ValueError('原目录前缀不能为空或只有分隔符')
    new = new_prefix.strip().replace('\\', '/').rstrip('/')
    plans = []
    for record in resource_records(root):
        path = record.path.replace('\\', '/')
        if path.casefold().startswith(old.casefold() + '/'):
            replacement = normalize_path(new + '/' + path[len(old) + 1:] if new else path[len(old) + 1:])
            if replacement != record.path and record.path_element is not None:
                plans.append((record.path_element, record.path, replacement))
    return plans


def game_path(filename, resolver):
    filename = os.path.abspath(filename)
    for root in resolver.roots:
        try:
            relative = os.path.relpath(filename, root)
        except ValueError:
            continue
        if relative != '..' and not relative.startswith('..' + os.sep):
            return relative.replace('\\', '/')
    return filename.replace('\\', '/')


def _active_reference(element):
    return (reference_kind(element) is not None and element.text not in (None, '', '-1')
            and not (element.tag == 'int4' and element.text == '0'))


def make_template(root, entry):
    """Bundle external textures inside the component; reject external node links."""
    if entry.tag != 'uiEntry' or entry.getroottree().getroot() is not root:
        raise ValueError('请选择当前文档中的一个 UI 节点')
    component = copy.deepcopy(entry)
    copied = dict(zip(entry.iter(), component.iter()))
    index = DocumentIndex(root)
    external = {}
    bindings = []
    warnings = set()
    for old, new in list(copied.items()):
        if isinstance(old.tag, str) and re.search('IDRef$', old.tag, re.IGNORECASE) and reference_kind(old) is None:
            warnings.add(old.tag)
        if not _active_reference(old):
            continue
        targets = index.resolve(old)
        if len(targets) != 1:
            raise ValueError('组件含缺失或不唯一的引用，无法保存模板：' + str(old.tag))
        target = targets[0]
        if target not in copied:
            if target.tag != 'tga':
                raise ValueError('组件引用了外部 UI/状态；请保存包含目标的更大父节点')
            if target not in external:
                # Texture definitions should be scalar data, never a second component.
                if any(child.tag in DEFINITION_TAGS or reference_kind(child) for child in target.iterdescendants()):
                    raise ValueError('外部贴图包含嵌套定义或引用，无法自动打包')
                external[target] = copy.deepcopy(target)
        bindings.append((new, copied[target] if target in copied else external[target]))
    if external:
        containers = component.findall('tgas')
        if len(containers) > 1:
            raise ValueError('组件有多个 tgas 集合，请先修复')
        if containers:
            container = containers[0]
        else:
            container = etree.Element('tgas')
            states = component.find('states')
            component.insert(list(component).index(states) if states is not None else len(component), container)
        container.extend(external.values())
    # Give the standalone template unique IDs, then bind by identity rather than raw ID.
    allocator = IdAllocator(etree.Element('ui'))
    for definition in component.iter(*DEFINITION_TAGS):
        ident = definition.find('id')
        if ident is None:
            raise ValueError('组件定义缺少 ID')
        ident.text = allocator.allocate()
    for reference, target in bindings:
        reference.text = target.findtext('id')
    for element in component.iter():
        sync_count(element)
    validate_template(component)
    package = etree.Element('tenshoComponent', version='1')
    package.append(component)
    payload = etree.tostring(package, encoding='utf-8', xml_declaration=True)
    if len(payload) > 16 * 1024 * 1024:
        raise ValueError('模板超过 16 MiB，请选择更小的组件')
    return payload, sorted(warnings)


def validate_template(component):
    errors = [issue[2] for issue in inspect_document(component) if issue[3] == 'error']
    if errors:
        raise ValueError('模板结构无效：' + '\n'.join(errors[:8]))
    index = DocumentIndex(component)
    if any(_active_reference(ref) and len(index.resolve(ref)) != 1 for ref in component.iter()):
        raise ValueError('模板包含未打包的外部引用')


def read_template(filename):
    if os.path.getsize(filename) > 16 * 1024 * 1024:
        raise ValueError('模板超过 16 MiB')
    parser = etree.XMLParser(resolve_entities=False, no_network=True, strip_cdata=False)
    tree = etree.parse(os.fspath(filename), parser)
    if tree.docinfo.doctype:
        raise ValueError('模板不支持 DTD 或实体声明')
    package = tree.getroot()
    if package.tag != 'tenshoComponent' or package.get('version') != '1' or len(package) != 1 or package[0].tag != 'uiEntry':
        raise ValueError('请选择版本 1 的 Tensho 组件模板')
    validate_template(package[0])
    return package[0]


def instantiate_template(root, component):
    validate_template(component)
    return clone_ui_entry(root, component)
