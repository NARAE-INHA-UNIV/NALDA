import os
import sys

from PySide6.QtWidgets import QWidget, QVBoxLayout
from PySide6.QtCore import QUrl, QObject, Slot
from PySide6.QtQuickWidgets import QQuickWidget

from .pfd_controller import PFDController

from .utils import resource_path


class DockableWidget(QWidget):
    """도킹 가능한 위젯 클래스"""

    # gcs_backend 인자를 추가
    #       DockableWidget 내부에서
    #       self.qml_widget.rootContext().setContextProperty("gcsBackend", gcs_backend)를
    #       호출하여 gcsBackend 객체를 해당 QML 컨텍스트에 등록
    def __init__(self, title: str, qml_path: str, gps_backend: QObject = None, dock_manager: QObject = None, pfd_controller: QObject = None, parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)

        layout = QVBoxLayout(self)
        self.qml_widget = QQuickWidget()

        # QML 소스를 로드하기 전에 컨텍스트 프로퍼티를 먼저 설정합니다.
        if gps_backend:
            self.qml_widget.rootContext().setContextProperty("gpsBackend", gps_backend)
        if dock_manager:
            self.qml_widget.rootContext().setContextProperty("dockManager", dock_manager)
        if pfd_controller:
            self.qml_widget.rootContext().setContextProperty("pfdController", pfd_controller)

        self.qml_widget.setSource(QUrl.fromLocalFile(resource_path(qml_path)))
        self.qml_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)

        context = self.qml_widget.rootContext()
        self.pfd_controller = PFDController()
        context.setContextProperty(
            "pfdController", self.pfd_controller)

        layout.addWidget(self.qml_widget)


class DockManager(QObject):
    """도크 위젯 관리자 - QML과 Python 간의 통신을 담당"""

    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.main_window = main_window

    @Slot(str)
    def toggle_dock_area(self, page_name):
        """페이지에 따라 도크 영역 토글"""
        if page_name == "FLIGHT":
            # MainPanel이면 도크 영역 보이기
            if not self.main_window.dock_area_visible:
                self.main_window.toggle_dock_area()
        else:
            # 다른 페이지면 도크 영역 숨기기
            if self.main_window.dock_area_visible:
                self.main_window.toggle_dock_area()

    @Slot()
    def showLocationHistory(self):
        """메인 윈도우에 Location History 창을 띄우도록 요청"""
        if hasattr(self.main_window, 'show_location_history'):
            self.main_window.show_location_history()

    @Slot()
    def showLocationHistory(self):
        """메인 윈도우에 Location History 창을 띄우도록 요청"""
        if hasattr(self.main_window, 'show_location_history'):
            self.main_window.show_location_history()
