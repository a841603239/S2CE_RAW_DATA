"""Literal document search and editor-only layer state; independent of Qt."""
from collections import Counter
from dataclasses import dataclass
import hashlib
import json
import os

from .document import canonical_id, owner_entry, reference_kind


def belongs_to(root, element):
    if element is None or root is None:
        return False
    while element.getparent() is not None:
        element = element.getparent()
    return element is root


@dataclass
class SearchRecord:
    element: object
    category: str
    value: str
    folded: str

    @property
    def entry(self):
        return owner_entry(self.element)


class SearchIndex:
    def __init__(self, root):
        self.records = []
        if root is None:
            return
        for element in root.iter():
            tag = element.tag
            if not isinstance(tag, str) or len(element) or not element.text:
                continue
            category = None
            if tag in ('title', 'title2'):
                category = '名称'
            elif tag == 'id' or reference_kind(element):
                category = 'ID'
            elif tag == 'path' and element.getparent() is not None and element.getparent().tag == 'tga':
                category = '贴图路径'
            elif tag in ('stateText', 'tooltip', 'tooltipText', 'script', 'text') or tag.startswith('string'):
                category = '文本'
            if category:
                value = element.text
                self.records.append(SearchRecord(element, category, value, value.casefold()))

    def search(self, query, category='全部', exact=False, limit=500):
        query = query.strip()
        if not query:
            return [], 0
        folded = query.casefold()
        result, total = [], 0
        for record in self.records:
            if category != '全部' and record.category != category:
                continue
            if exact and record.category == 'ID' and query.isascii() and query.isdecimal():
                matches = canonical_id(record.value) == canonical_id(query)
            else:
                matches = record.folded == folded if exact else folded in record.folded
            if matches:
                total += 1
                if len(result) < limit:
                    result.append(record)
        return result, total


def settings_key(path):
    normalized = os.path.normcase(os.path.realpath(os.path.abspath(os.fspath(path))))
    return 'document_view/' + hashlib.sha256(normalized.encode('utf-8')).hexdigest()


class NodeViewState:
    def __init__(self):
        self.locked = set()
        self.hidden = set()
        self.saved_keys = {}

    def remember_saved_ids(self, root):
        entries = list(root.iter('uiEntry')) if root is not None else []
        values = {entry: canonical_id(entry.findtext('id')) for entry in entries}
        counts = Counter(values.values())
        self.saved_keys = {entry: value for entry, value in values.items()
                           if value and value.isascii() and value.isdecimal() and counts[value] == 1}

    def restore(self, root, payload):
        self.locked.clear()
        self.hidden.clear()
        self.remember_saved_ids(root)
        try:
            data = json.loads(payload) if isinstance(payload, str) and payload else {}
        except (ValueError, TypeError):
            data = {}
        if not isinstance(data, dict) or data.get('version') != 1:
            return
        for name in ('locked', 'hidden'):
            values = data.get(name, [])
            if isinstance(values, list):
                keys = {value for value in values if isinstance(value, str)}
                getattr(self, name).update(entry for entry, key in self.saved_keys.items() if key in keys)

    def serialize(self):
        # Use last-saved IDs until XML saves successfully: discarding an ID edit is safe.
        return json.dumps({'version': 1, **{
            name: sorted(self.saved_keys[entry] for entry in getattr(self, name) if entry in self.saved_keys)
            for name in ('locked', 'hidden')}}, ensure_ascii=False)

    def effective(self, entry, name):
        entries = getattr(self, name)
        while entry is not None:
            if entry in entries:
                return True
            entry = owner_entry(entry.getparent())
        return False
