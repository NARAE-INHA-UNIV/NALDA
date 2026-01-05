from PySide6.QtWidgets import QWidget
from PySide6.QtCore import Qt, QObject, Signal, Slot
from PySide6.QtGui import QPainter, QColor, QPen, QFont
from PySide6.QtGui import QFontMetrics


class TooltipManager(QObject):
    """툴팁 관리자 - QML과 Python 간의 통신을 담당"""

    # QML에서 호출할 시그널
    showTooltip = Signal(str, int, int)  # 메시지, x, y
    hideTooltip = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.tooltip_widget = None

    @Slot(str, int, int)
    def show_tooltip(self, message, x, y):
        """QML에서 호출되는 툴팁 표시 메서드"""
        if not self.tooltip_widget:
            self.tooltip_widget = CustomTooltip()

        self.tooltip_widget.set_tooltip_text(message)
        self.tooltip_widget.move(x + 5, y + 11)
        self.tooltip_widget.show()

    @Slot()
    def hide_tooltip(self):
        """QML에서 호출되는 툴팁 숨김 메서드"""
        if self.tooltip_widget:
            self.tooltip_widget.hide()


class CustomTooltip(QWidget):
    """커스텀 툴팁 위젯"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.ToolTip)
        self.setAttribute(Qt.WA_TranslucentBackground)

        # 툴팁 텍스트
        self.tooltip_text = ""
        self.padding = 12
        self.border_radius = 8

    def set_tooltip_text(self, text):
        """툴팁 텍스트 설정"""
        self.tooltip_text = text
        self._calculate_size()
        self.update()

    def _calculate_size(self):
        """텍스트 크기에 맞춰 위젯 크기 계산"""
        if not self.tooltip_text:
            self.setFixedSize(50, 30)
            return

        font = QFont()
        font.setPixelSize(14)

        # QFontMetrics를 사용해 텍스트 크기 계산
        metrics = QFontMetrics(font)
        text_rect = metrics.boundingRect(self.tooltip_text)

        # 패딩을 포함한 최종 크기 설정
        width = text_rect.width() + (self.padding * 2)
        height = text_rect.height() + (self.padding * 2)

        # 최소/최대 크기 제한
        width = max(50, min(300, width))
        height = max(30, min(100, height))

        self.setFixedSize(width, height)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        # 둥근 모서리 배경
        background_color = QColor("#3a3a3a")
        painter.setBrush(background_color)
        painter.setPen(QPen(QColor("#606060"), 1))
        painter.drawRoundedRect(self.rect().adjusted(1, 1, -1, -1),
                                self.border_radius, self.border_radius)

        # 텍스트
        painter.setPen(QColor("#ffffff"))
        font = QFont()
        font.setPixelSize(14)
        painter.setFont(font)

        # 텍스트를 중앙에 그리기
        text_rect = self.rect().adjusted(self.padding//2, self.padding//2,
                                         -self.padding//2, -self.padding//2)
        painter.drawText(text_rect, Qt.AlignCenter |
                         Qt.TextWordWrap, self.tooltip_text)
