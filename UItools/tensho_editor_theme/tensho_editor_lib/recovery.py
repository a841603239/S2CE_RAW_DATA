"""Atomic, bounded, self-contained recovery copies. Never writes source XML files."""
from dataclasses import dataclass
import hashlib
import json
import math
import os
from pathlib import Path
import re
import tempfile
import time
import uuid
import zipfile

from .changes import DocumentSnapshot, parse_xml

SUFFIX = '.tensho-recovery'
NAME = re.compile(r'[0-9a-f]{32}-[0-9a-f]{32}-[0-9a-f]{32}\.tensho-recovery')
MAX_XML = 64 * 1024 * 1024
MAX_META = 16 * 1024 * 1024


def source_key(source):
    value = os.path.normcase(os.path.abspath(source)) if source else '(untitled)'
    return hashlib.sha256(value.encode('utf-8')).hexdigest()[:32]


def sha(payload):
    return hashlib.sha256(payload).hexdigest()


@dataclass
class RecoveryRecord:
    path: Path
    source: str
    created: float
    session: str
    digest: str
    declaration: bool
    disk_hash: object


class RecoveryStore:
    def __init__(self, directory):
        self.directory = Path(directory).resolve()

    def _managed(self, path):
        path = Path(path)
        if path.parent.resolve() != self.directory or not NAME.fullmatch(path.name) or path.is_symlink():
            raise ValueError('不是当前恢复目录中的受管副本')
        return path

    def _metadata(self, archive):
        expected = {'metadata.json', 'snapshot.xml', 'baseline.xml'}
        if len(archive.infolist()) != 3 or set(archive.namelist()) != expected:
            raise ValueError('恢复副本结构无效')
        for name in expected:
            limit = MAX_META if name == 'metadata.json' else MAX_XML
            if archive.getinfo(name).file_size > limit:
                raise ValueError('恢复副本超过读取上限')
        metadata = json.loads(archive.read('metadata.json'))
        if (not isinstance(metadata, dict) or type(metadata.get('version')) is not int or metadata.get('version') != 1 or not isinstance(metadata.get('source'), str) or
                not isinstance(metadata.get('session'), str) or not re.fullmatch('[0-9a-f]{32}', metadata['session']) or
                type(metadata.get('created')) not in (int, float) or not 0 <= metadata['created'] <= 253402300799 or
                not math.isfinite(metadata['created']) or '\0' in metadata['source'] or
                (metadata['source'] and not os.path.isabs(metadata['source'])) or
                type(metadata.get('declaration')) is not bool or
                (metadata.get('disk_hash') is not None and not re.fullmatch('[0-9a-f]{64}', str(metadata['disk_hash']))) or
                any(not re.fullmatch('[0-9a-f]{64}', str(metadata.get(name, ''))) for name in ('digest', 'baseline_digest'))):
            raise ValueError('恢复副本元数据无效')
        return metadata

    def _record(self, path, meta):
        if not path.name.startswith(source_key(meta['source']) + '-' + meta['session'] + '-'):
            raise ValueError('恢复副本名称与内容不一致')
        return RecoveryRecord(path, meta['source'], meta['created'], meta['session'],
            meta['digest'], meta['declaration'], meta.get('disk_hash'))

    def scan(self):
        records, errors = [], []
        if not self.directory.exists():
            return records, errors
        for path in self.directory.glob('*' + SUFFIX):
            if not NAME.fullmatch(path.name):
                continue
            try:
                self._managed(path)
                with zipfile.ZipFile(path) as archive:
                    records.append(self._record(path, self._metadata(archive)))
            except (OSError, ValueError, KeyError, zipfile.BadZipFile, RuntimeError) as error:
                errors.append((path, str(error)))
        records.sort(key=lambda record: (record.created, record.path.name), reverse=True)
        return records, errors

    def write(self, source, session, tree, baseline, declaration, disk_hash=None, now=None):
        if not re.fullmatch('[0-9a-f]{32}', session):
            raise ValueError('恢复会话 ID 无效')
        payload = etree_bytes(tree)
        if len(payload) > MAX_XML or len(baseline.payload) > MAX_XML:
            raise ValueError('恢复副本超过 64 MiB XML 上限')
        source = os.path.abspath(os.fspath(source)) if source else ''
        created = time.time() if now is None else float(now)
        metadata = {'version': 1, 'source': source, 'session': session, 'created': created,
            'digest': sha(payload), 'baseline_digest': sha(baseline.payload),
            'declaration': bool(declaration), 'disk_hash': disk_hash, 'pairs': baseline.identity_pairs(tree)}
        meta_bytes = json.dumps(metadata, ensure_ascii=False).encode('utf-8')
        if len(meta_bytes) > MAX_META or not math.isfinite(created) or not 0 <= created <= 253402300799:
            raise ValueError('恢复副本元数据超过上限或时间无效')
        self.directory.mkdir(parents=True, exist_ok=True)
        path = self.directory / f'{source_key(source)}-{session}-{uuid.uuid4().hex}{SUFFIX}'
        with tempfile.NamedTemporaryFile(prefix='.tensho-', suffix='.tmp', dir=self.directory, delete=False) as stream:
            staged = Path(stream.name)
        try:
            with staged.open('wb') as stream:
                with zipfile.ZipFile(stream, 'w', zipfile.ZIP_DEFLATED) as archive:
                    archive.writestr('metadata.json', meta_bytes)
                    archive.writestr('snapshot.xml', payload)
                    archive.writestr('baseline.xml', baseline.payload)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(staged, path)
        finally:
            staged.unlink(missing_ok=True)
        return self._record(path, metadata)

    def read(self, path):
        path = self._managed(path)
        with zipfile.ZipFile(path) as archive:
            meta = self._metadata(archive)
            record = self._record(path, meta)
            payload = archive.read('snapshot.xml')
            baseline_bytes = archive.read('baseline.xml')
        if sha(payload) != meta['digest'] or sha(baseline_bytes) != meta['baseline_digest']:
            raise ValueError('恢复副本校验失败，内容可能不完整')
        tree = parse_xml(payload)
        baseline = DocumentSnapshot(parse_xml(baseline_bytes)).rebind(tree, meta.get('pairs'))
        return record, tree, baseline

    def delete(self, path):
        self._managed(path).unlink(missing_ok=True)

    def clear(self, source, session):
        records, _ = self.scan()
        for record in records:
            if source_key(record.source) == source_key(source) and record.session == session:
                self.delete(record.path)

    def cleanup(self, copies=10, days=30, total=100, now=None):
        copies, days, total = max(1, int(copies)), max(1, int(days)), max(1, int(total))
        now = time.time() if now is None else float(now)
        records, errors = self.scan()
        kept = {}
        remaining = 0
        for record in records:
            key = source_key(record.source)
            if (record.created < now - days * 86400 or kept.get(key, 0) >= copies or remaining >= total):
                self.delete(record.path)
            else:
                kept[key] = kept.get(key, 0) + 1
                remaining += 1
        # Valid copies take priority within the global cap. Unrelated files are never touched.
        for path, _ in sorted(errors, key=lambda item: item[0].name):
            try:
                if path.stat().st_mtime < now - days * 86400 or remaining >= total:
                    self.delete(path)
                else:
                    remaining += 1
            except FileNotFoundError:
                pass


def etree_bytes(tree):
    from lxml import etree
    return etree.tostring(tree, encoding='utf-8')
