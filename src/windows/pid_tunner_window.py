from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QMainWindow
from PySide6.QtQuickWidgets import QQuickWidget

from backend.utils import resource_path


class PIDTunnerWindow(QMainWindow):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("PID Gain Tunner")
        self.resize(600, 500)

        self.qml_widget = QQuickWidget()

        # 전역 스타일 설정
        engine = self.qml_widget.engine()
        styles_path = resource_path("frontend/styles")
        engine.addImportPath(styles_path)

        qml_file = resource_path("frontend/pages/setup/attitude-overview/windows/PIDTunner.qml")
        self.qml_widget.setSource(QUrl.fromLocalFile(qml_file))
        self.qml_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)
        self.setCentralWidget(self.qml_widget)
