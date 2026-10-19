"""Resource resolution and one shared, bounded LRU for original/tinted images."""
import os
from collections import OrderedDict

import numpy as np
from PIL import Image
from PySide6.QtGui import QImage, QPixmap


class ResourceResolver:
    def __init__(self):
        self.roots = []
        self.revision = 0

    def set_roots(self, roots):
        roots = list(dict.fromkeys(os.fspath(root) for root in roots if root))
        if roots != self.roots:
            self.roots = roots
            self.revision += 1

    def resolve(self, path):
        if not path:
            return None
        path = os.fspath(path).replace('\\', '/').strip()
        if os.path.isabs(path) and os.path.isfile(path):
            return path
        for root in self.roots:
            for sub in (path, path.lower(), path.upper()):
                candidate = os.path.join(root, sub)
                if os.path.isfile(candidate):
                    return candidate
        return None


class PixmapCache:
    """Budget covers cached pixel bytes; Qt/GPU overhead and live paint values are extra."""
    def __init__(self, resolver, max_bytes=128 * 1024 * 1024, max_entries=1024, max_errors=200):
        self.resolver = resolver
        self.max_bytes = max(0, int(max_bytes))
        self.max_entries = max(0, int(max_entries))
        self.max_errors = max(0, int(max_errors))
        self._raw = {}
        self._tinted = {}
        self._lru = OrderedDict()
        self.errors = OrderedDict()
        self.current_bytes = 0
        self.hits = self.misses = self.evictions = 0
        self._revision = resolver.revision

    def clear(self):
        self._raw.clear()
        self._tinted.clear()
        self._lru.clear()
        self.errors.clear()
        self.current_bytes = 0
        self.hits = self.misses = self.evictions = 0
        self._revision = self.resolver.revision

    def _check_roots(self):
        if self._revision != self.resolver.revision:
            self.clear()

    def _get(self, kind, key):
        self._check_roots()
        mapping = self._raw if kind == 'raw' else self._tinted
        if key in mapping:
            self._lru.move_to_end((kind, key))
            self.hits += 1
            return True, mapping[key]
        self.misses += 1
        return False, None

    def _put(self, kind, key, pixmap):
        mapping = self._raw if kind == 'raw' else self._tinted
        cost = 0 if pixmap is None else pixmap.width() * pixmap.height() * max(4, (pixmap.depth() + 7) // 8)
        if not self.max_entries or cost > self.max_bytes:
            return pixmap
        while self._lru and (self.current_bytes + cost > self.max_bytes or len(self._lru) >= self.max_entries):
            (old_kind, old_key), old_cost = self._lru.popitem(last=False)
            (self._raw if old_kind == 'raw' else self._tinted).pop(old_key, None)
            self.current_bytes -= old_cost
            self.evictions += 1
        mapping[key] = pixmap
        self._lru[(kind, key)] = cost
        self.current_bytes += cost
        return pixmap

    def _record_error(self, path, message):
        if not self.max_errors:
            return
        self.errors[path] = message
        self.errors.move_to_end(path)
        while len(self.errors) > self.max_errors:
            self.errors.popitem(last=False)

    def stats(self):
        self._check_roots()
        return {'bytes': self.current_bytes, 'max_bytes': self.max_bytes,
                'entries': len(self._lru), 'max_entries': self.max_entries,
                'hits': self.hits, 'misses': self.misses, 'evictions': self.evictions,
                'errors': len(self.errors)}

    def get_raw(self, path):
        if not path:
            return None
        found, pixmap = self._get('raw', path)
        if found:
            return pixmap
        try:
            real = self.resolver.resolve(path)
            if real is None:
                raise FileNotFoundError('未在当前资源目录找到文件')
            with Image.open(real) as original:
                image = original.convert('RGBA')
                data = image.tobytes('raw', 'RGBA')
                qimage = QImage(data, image.width, image.height, QImage.Format_RGBA8888)
                pixmap = QPixmap.fromImage(qimage)
            if pixmap.isNull():
                raise ValueError('无法生成图片预览')
        except (OSError, ValueError, Image.DecompressionBombError) as error:
            self._record_error(path, f'{type(error).__name__}: {error}')
            return self._put('raw', path, None)
        self.errors.pop(path, None)
        return self._put('raw', path, pixmap)

    def get_tinted(self, path, r, g, b, a):
        channels = tuple(max(0, min(255, int(channel))) for channel in (r, g, b, a))
        if channels == (255, 255, 255, 255):
            return self.get_raw(path)
        key = (path,) + channels
        found, pixmap = self._get('tinted', key)
        if found:
            return pixmap
        raw = self.get_raw(path)
        if raw is None or raw.isNull():
            # Only one negative entry per path, regardless of tint combinations.
            return None
        image = raw.toImage().convertToFormat(QImage.Format_RGBA8888)
        width, height = image.width(), image.height()
        array = np.frombuffer(image.bits(), dtype=np.uint8).reshape((height, width, 4)).copy()
        for channel, multiplier in enumerate(channels):
            if multiplier != 255:
                array[..., channel] = (array[..., channel].astype(np.uint16) * multiplier // 255).astype(np.uint8)
        tinted = QImage(array.tobytes(), width, height, QImage.Format_RGBA8888).copy()
        return self._put('tinted', key, QPixmap.fromImage(tinted))
