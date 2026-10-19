"""Light editor chrome, palette and scalable line icons; independent of XML data."""
from functools import lru_cache

from PySide6.QtCore import QByteArray, QRectF, Qt
from PySide6.QtGui import QColor, QFont, QFontDatabase, QIcon, QPainter, QPalette, QPixmap
from PySide6.QtSvg import QSvgRenderer

from . import theme_resources  # Registers the :/tensho/light/ SVG controls.


COLORS = {
    'window': '#F3F5F8', 'surface': '#FFFFFF', 'subtle': '#F7F9FC',
    'border': '#DDE3EB', 'text': '#253044', 'muted': '#657086',
    'disabled': '#939EAF', 'accent': '#356AE6', 'accent_hover': '#2858C9',
    'selection': '#E8EFFF', 'grid': '#E6EAF1', 'grid_major': '#D6DDE8',
    'canvas': '#EDF1F6', 'danger': '#B83B48', 'warning': '#946116',
    'success': '#247653', 'guide': '#7389C1',
}


def color(name):
    return QColor(COLORS[name])


def ui_font(points=9.5, bold=False):
    families = set(QFontDatabase.families())
    family = next((name for name in ('Microsoft YaHei UI', 'Microsoft YaHei', 'Segoe UI', 'Noto Sans CJK SC')
                   if name in families), '')
    font = QFont(family) if family else QFontDatabase.systemFont(QFontDatabase.GeneralFont)
    font.setPointSizeF(points)
    font.setBold(bold)
    return font


def code_font():
    font = QFontDatabase.systemFont(QFontDatabase.FixedFont)
    if 'Consolas' in QFontDatabase.families():
        font.setFamily('Consolas')
    font.setPointSizeF(9.5)
    return font


_SHAPES = {
    'open': '<path d="M3 7V5h6l2 2h9v3M3 10h19l-4 10H2z"/>',
    'save': '<path d="M4 3h13l4 4v14H3V3zM7 3v6h10V3M7 21v-8h10v8"/>',
    'refresh': '<path d="M20 7a8 8 0 1 0 0 10M20 3v5h-5"/>',
    'folder': '<path d="M3 5h6l2 3h10v12H3z"/>',
    'grid': '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 3v18M15 3v18M3 9h18M3 15h18"/>',
    'move': '<path d="M12 2v20M2 12h20M9 5l3-3 3 3M9 19l3 3 3-3M5 9l-3 3 3 3M19 9l3 3-3 3"/>',
    'undo': '<path d="M4 5v6h6M4 11c3-7 16-6 16 3v5"/>',
    'redo': '<path d="M20 5v6h-6M20 11C17 4 4 5 4 14v5"/>',
    'align': '<path d="M4 3v18M8 5h12v5H8zM8 14h8v5H8z"/>',
    'state': '<rect x="3" y="3" width="7" height="6" rx="1"/><rect x="14" y="15" width="7" height="6" rx="1"/><path d="M7 9v9h7M11 15l3 3-3 3"/>',
    'search': '<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>',
    'image': '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8" cy="8" r="2"/><path d="m3 17 5-5 4 4 4-5 5 6"/>',
    'check': '<circle cx="12" cy="12" r="9"/><path d="m7 12 3 3 7-7"/>',
    'changes': '<path d="M7 3H3v18h4M17 3h4v18h-4M8 8h8M12 4v8M8 17h8"/>',
    'recovery': '<path d="M3 5v6h6M3 11a9 9 0 1 1 1 7M12 7v6l4 2"/>',
    'settings': '<path d="M4 3v18M12 3v18M20 3v18"/><path d="M1 8h6M9 16h6M17 8h6"/>',
    'copy': '<path d="M7 7V3h14v14h-4"/><rect x="3" y="7" width="14" height="14" rx="1"/>',
    'delete': '<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',
    'locate': '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>',
    'batch': '<path d="M9 6h12M9 12h12M9 18h12M3 6h1M3 12h1M3 18h1"/>',
}


@lru_cache(maxsize=80)
def icon(name, tone='muted'):
    """Rasterize built-in vectors at several sizes/DPRs, without external asset paths."""
    shape = _SHAPES[name]
    result = QIcon()
    for mode, stroke in ((QIcon.Normal, COLORS[tone]), (QIcon.Disabled, COLORS['disabled'])):
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">'
               '<g fill="none" stroke="' + stroke + '" stroke-width="1.65" stroke-linecap="round" '
               'stroke-linejoin="round">' + shape + '</g></svg>')
        renderer = QSvgRenderer(QByteArray(svg.encode('utf-8')))
        for size in (16, 20, 24):
            for ratio in (1, 2, 3):
                pixmap = QPixmap(size * ratio, size * ratio)
                pixmap.setDevicePixelRatio(ratio)
                pixmap.fill(Qt.transparent)
                painter = QPainter(pixmap)
                renderer.render(painter, QRectF(0, 0, size, size))
                painter.end()
                result.addPixmap(pixmap, mode)
    return result


_STYLE = '''
QWidget { color: %(text)s; }
QMainWindow, QDialog { background: %(window)s; }
QWidget#EditorSurface { background: %(window)s; }
QWidget#InspectorPanel, QWidget#HierarchyPanel {
    background: %(surface)s; border: 1px solid %(border)s; border-radius: 6px;
}
QLabel { background: transparent; }
QLabel#PanelHeading {
    color: %(text)s; font-size: 14px; font-weight: 600;
    padding: 10px 12px; border: none; border-bottom: 1px solid %(border)s;
}
QLabel#SelectionHeader {
    color: %(text)s; font-size: 14px; font-weight: 600;
    padding: 10px 4px; border-bottom: 1px solid %(border)s;
}
QLabel#SelectionNote { color: %(warning)s; padding: 2px 4px; }
QLabel#CanvasHeading { color: %(muted)s; font-weight: 600; padding: 2px 4px 6px 4px; }
QLabel#ResourcePreview { background: %(subtle)s; border: 1px solid %(border)s; border-radius: 6px; }
QMenuBar { background: %(surface)s; border-bottom: 1px solid %(border)s; padding: 3px 8px; }
QMenuBar::item { background: transparent; padding: 6px 10px; border-radius: 4px; }
QMenuBar::item:selected, QMenuBar::item:pressed { background: %(selection)s; color: %(accent)s; }
QMenu { background: %(surface)s; border: 1px solid %(border)s; padding: 5px; }
QMenu::item { padding: 7px 26px 7px 24px; border-radius: 4px; }
QMenu::item:selected { background: %(selection)s; color: %(accent)s; }
QMenu::item:disabled { color: %(disabled)s; }
QMenu::separator { height: 1px; background: %(border)s; margin: 5px 7px; }
QToolBar { background: %(surface)s; border: none; border-bottom: 1px solid %(border)s; padding: 6px 8px; spacing: 3px; }
QToolBar::separator { background: %(border)s; width: 1px; margin: 5px 8px; }
QToolButton { background: transparent; border: 1px solid transparent; border-radius: 4px; padding: 6px 8px; }
QToolButton:hover { background: %(subtle)s; border-color: %(border)s; }
QToolButton:pressed, QToolButton:checked { background: %(selection)s; color: %(accent)s; }
QToolButton:disabled { color: %(disabled)s; }
QPushButton { background: %(surface)s; border: 1px solid %(border)s; border-radius: 5px; padding: 6px 12px; min-height: 18px; }
QPushButton:hover { background: %(subtle)s; border-color: #B7C5DD; }
QPushButton:pressed { background: %(selection)s; border-color: %(accent)s; }
QPushButton:focus { border-color: %(accent)s; }
QPushButton[primary="true"], QDialogButtonBox QPushButton:default { background: %(accent)s; color: white; border-color: %(accent)s; }
QPushButton[primary="true"]:hover, QDialogButtonBox QPushButton:default:hover { background: %(accent_hover)s; }
QPushButton[danger="true"] { color: %(danger)s; }
QPushButton:disabled { background: %(subtle)s; color: %(disabled)s; border-color: %(border)s; }
QLineEdit, QAbstractSpinBox, QComboBox {
    background: %(surface)s; border: 1px solid %(border)s; border-radius: 4px;
    padding: 5px 7px; min-height: 19px; selection-background-color: %(selection)s; selection-color: %(text)s;
}
QLineEdit:hover, QAbstractSpinBox:hover, QComboBox:hover { border-color: #BAC7DC; }
QLineEdit:focus, QAbstractSpinBox:focus, QComboBox:focus { border-color: %(accent)s; }
QLineEdit:disabled, QAbstractSpinBox:disabled, QComboBox:disabled { background: %(subtle)s; color: %(disabled)s; }
QAbstractSpinBox { padding-right: 24px; }
QSpinBox::up-button, QDoubleSpinBox::up-button { subcontrol-origin: border; subcontrol-position: top right; width: 22px; border: 1px solid %(border)s; background: %(subtle)s; border-top-right-radius: 4px; }
QSpinBox::down-button, QDoubleSpinBox::down-button { subcontrol-origin: border; subcontrol-position: bottom right; width: 22px; border: 1px solid %(border)s; border-top: none; background: %(subtle)s; border-bottom-right-radius: 4px; }
QSpinBox::up-arrow, QDoubleSpinBox::up-arrow { image: url(:/tensho/light/chevron-up.svg); width: 10px; height: 10px; }
QSpinBox::down-arrow, QDoubleSpinBox::down-arrow { image: url(:/tensho/light/chevron-down.svg); width: 10px; height: 10px; }
QComboBox { padding-right: 24px; }
QComboBox::drop-down { width: 24px; border: none; }
QComboBox::down-arrow { image: url(:/tensho/light/chevron-down.svg); width: 12px; height: 12px; }
QComboBox QAbstractItemView { background: %(surface)s; border: 1px solid %(border)s; selection-background-color: %(selection)s; selection-color: %(text)s; outline: 0; }
QCheckBox, QRadioButton { spacing: 7px; padding: 3px 0; background: transparent; }
QCheckBox:disabled, QRadioButton:disabled, QLabel:disabled { color: %(disabled)s; }
QCheckBox::indicator, QTreeView::indicator { width: 14px; height: 14px; border: 1px solid #B4C0D2; border-radius: 3px; background: %(surface)s; }
QCheckBox::indicator:hover, QTreeView::indicator:hover { border-color: %(accent)s; }
QCheckBox::indicator:checked, QTreeView::indicator:checked { image: url(:/tensho/light/check.svg); background: %(accent)s; border-color: %(accent)s; }
QCheckBox::indicator:indeterminate, QTreeView::indicator:indeterminate { image: url(:/tensho/light/minus.svg); background: %(accent)s; border-color: %(accent)s; }
QCheckBox::indicator:disabled, QTreeView::indicator:disabled { background-color: #E3E8F0; border-color: %(border)s; }
QGroupBox { background: %(surface)s; border: 1px solid %(border)s; border-radius: 5px; margin-top: 13px; padding: 14px 10px 10px 10px; }
QGroupBox::title { subcontrol-origin: margin; subcontrol-position: top left; left: 10px; padding: 0 5px; color: %(muted)s; }
QTreeView, QListView, QTableView, QPlainTextEdit, QTextEdit {
    background: %(surface)s; alternate-background-color: %(subtle)s; border: 1px solid %(border)s; border-radius: 5px;
    selection-background-color: %(selection)s; selection-color: %(text)s; outline: 0;
}
QTreeView::item, QListView::item, QTableView::item { min-height: 26px; padding: 2px 4px; border: none; }
QTreeView::item:hover, QListView::item:hover, QTableView::item:hover { background: #F1F5FD; }
QTreeView::item:selected, QListView::item:selected, QTableView::item:selected { background: %(selection)s; color: %(text)s; }
QTreeView::item:selected:active { color: #234DAB; }
QTreeView#HierarchyTree { border: none; border-radius: 0; }
QTreeView::branch:has-children:closed { image: url(:/tensho/light/chevron-right.svg); }
QTreeView::branch:has-children:open { image: url(:/tensho/light/chevron-down.svg); }
QTreeView:focus, QPlainTextEdit:focus, QTextEdit:focus { border-color: #A7BCEB; }
QHeaderView { background: %(subtle)s; border: none; }
QHeaderView::section { background: %(subtle)s; color: %(muted)s; border: none; border-bottom: 1px solid %(border)s; padding: 8px 6px; font-weight: 600; }
QPlainTextEdit { font-family: "Consolas"; padding: 6px; }
QSplitter::handle { background: %(window)s; }
QSplitter::handle:horizontal { width: 7px; }
QSplitter::handle:vertical { height: 7px; }
QSplitter::handle:hover { background: #DCE5F5; }
QTabWidget::pane { border: 1px solid %(border)s; border-radius: 4px; background: %(surface)s; padding: 4px; }
QTabBar::tab { background: transparent; color: %(muted)s; padding: 9px 14px; border-bottom: 2px solid transparent; }
QTabBar::tab:selected { color: %(accent)s; border-bottom-color: %(accent)s; background: %(surface)s; }
QTabBar::tab:hover:!selected { background: #EBEFF6; }
QDockWidget::title { background: %(surface)s; padding: 9px; border-bottom: 1px solid %(border)s; }
QStatusBar { background: %(surface)s; color: %(muted)s; border-top: 1px solid %(border)s; padding: 3px 8px; }
QStatusBar::item { border: none; }
QScrollBar:vertical { background: transparent; width: 12px; margin: 2px; }
QScrollBar:horizontal { background: transparent; height: 12px; margin: 2px; }
QScrollBar::handle:vertical { background: #C3CBD8; border-radius: 4px; min-height: 25px; }
QScrollBar::handle:horizontal { background: #C3CBD8; border-radius: 4px; min-width: 25px; }
QScrollBar::handle:hover { background: #9AAAC2; }
QScrollBar::add-line, QScrollBar::sub-line { width: 0; height: 0; border: none; background: transparent; }
QScrollBar::add-page, QScrollBar::sub-page { background: transparent; }
QToolTip { background: %(text)s; color: white; border: none; padding: 6px 8px; }
QGraphicsView { border: 1px solid %(border)s; border-radius: 5px; }
'''


def apply_light_theme(app):
    """Apply once per QApplication, including windows created after the main window."""
    if app is None or app.property('tenshoLightTheme'):
        return
    app.setStyle('Fusion')
    palette = QPalette()
    for role, name in ((QPalette.Window, 'window'), (QPalette.WindowText, 'text'),
                       (QPalette.Base, 'surface'), (QPalette.AlternateBase, 'subtle'),
                       (QPalette.Text, 'text'), (QPalette.Button, 'surface'),
                       (QPalette.ButtonText, 'text'), (QPalette.Highlight, 'selection'),
                       (QPalette.HighlightedText, 'text'), (QPalette.Link, 'accent'),
                       (QPalette.ToolTipBase, 'text'), (QPalette.ToolTipText, 'surface'),
                       (QPalette.PlaceholderText, 'disabled')):
        palette.setColor(role, color(name))
    for role in (QPalette.Text, QPalette.ButtonText, QPalette.WindowText):
        palette.setColor(QPalette.Disabled, role, color('disabled'))
    app.setPalette(palette)
    app.setFont(ui_font())
    app.setStyleSheet(_STYLE % COLORS)
    app.setProperty('tenshoLightTheme', True)


def primary(button):
    button.setProperty('primary', True)


def destructive(button):
    button.setProperty('danger', True)
