from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QMainWindow
from PySide6.QtQuickWidgets import QQuickWidget

from backend.utils import resource_path


class ManualGpsWindow(QMainWindow):
    def __init__(self, gps_backend, parent=None):
        super().__init__(parent)
        self.setWindowTitle("[테스트용] Manual GPS Input")
        self.resize(400, 300)

        self.qml_widget = QQuickWidget()

        # 소스 로드 전에 컨텍스트 설정
        self.qml_widget.rootContext().setContextProperty("gpsManager", gps_backend)

        qml_file = resource_path("frontend/pages/flight/nd/windows/ManualGpsInput.qml")
        self.qml_widget.setSource(QUrl.fromLocalFile(qml_file))
        self.qml_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)
        self.setCentralWidget(self.qml_widget)
