from PySide6.QtCore import QObject, Slot


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
