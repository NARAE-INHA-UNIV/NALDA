import sys
import os

# QML에서 로컬 파일 읽기를 허용하는 환경변수 설정
os.environ['QML_XHR_ALLOW_FILE_READ'] = '1'

from PySide6.QtWidgets import QApplication, QMainWindow, QDockWidget
from PySide6.QtCore import QUrl, Qt, Slot
from PySide6.QtGui import QFontDatabase, QFont
from PySide6.QtQuickWidgets import QQuickWidget

from backend.utils import resource_path
from backend.gps_backend import GpsBackend
from backend.dock import DockManager, DockableWidget
from backend.initializePortSelect import InitializePortSelect
from backend.tooltip import TooltipManager
from windows.location_history_window import LocationHistoryWindow
from windows.manual_gps_window import ManualGpsWindow


class MainWindow(QMainWindow):

    def __init__(self):
        super().__init__()
        self.setWindowTitle("NALDA")

        # 스타일시트 로드
        self.load_stylesheet()

        # 중앙 위젯 설정
        self.setup_central_widget()

        # 도크 위젯들 생성
        self.setup_dock_widgets()

        # 메뉴바 설정
        self.setup_menu_bar()

        # 도크 영역 초기 상태 설정
        self.dock_area_visible = True
        self.dock_area_width = self.width() - 80

        # 윈도우 크기 변경 이벤트 연결
        self.resizeEvent = self.on_resize

        # 초기 도크 너비 설정
        self.set_dock_width(self.dock_area_width)

        # 전체화면으로 변경
        # 마지막에 호출해야 레이아웃이 제대로 적용됨
        self.showMaximized()

    def load_stylesheet(self):
        """스타일시트 파일 로드"""
        try:
            with open(resource_path("src/styles.qss"), 'r', encoding='utf-8') as file:
                stylesheet = file.read()
                self.setStyleSheet(stylesheet)
        except FileNotFoundError:
            print(f"스타일시트 파일을 찾을 수 없습니다:")
        except Exception as e:
            print(f"스타일시트 로드 중 오류 발생: {e}")

    def setup_central_widget(self):
        """중앙 위젯 설정"""
        central_widget = QQuickWidget()
        qml_file = resource_path("src/main.qml")
        central_widget.setSource(QUrl.fromLocalFile(qml_file))
        central_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)

        # QML 컨텍스트에 매니저들 등록
        self.tooltip_manager = TooltipManager()
        self.dock_manager = DockManager(self)
        self.port_manager = InitializePortSelect()
        self.gps_backend = GpsBackend()

        # Port-GPS 백엔드 연결: 포트 연결 성공 시 GPS 모니터링 시작
        self.port_manager.connectionSuccessful.connect(self.gps_backend.start_gps_monitoring)

        context = central_widget.rootContext()
        context.setContextProperty("tooltipManager", self.tooltip_manager)
        context.setContextProperty("dockManager", self.dock_manager)
        context.setContextProperty("initializePortSelect", self.port_manager)
        context.setContextProperty("gpsBackend", self.gps_backend)

        self.setCentralWidget(central_widget)

        # Location History 창을 관리하기 위한 변수
        self.history_window = None

    @Slot()
    def show_location_history(self):
        """Location History 창을 띄우는 슬롯"""
        if self.history_window is None:
            self.history_window = LocationHistoryWindow(self.gps_backend, self)
            self.history_window.setAttribute(Qt.WA_DeleteOnClose)
            self.history_window.destroyed.connect(self.on_history_window_destroyed)
            self.history_window.show()
        else:
            self.history_window.activateWindow()

    def on_history_window_destroyed(self):
        """창이 닫힐 때 변수를 None으로 초기화"""
        self.history_window = None

    @Slot()
    def show_algorithm_input_panel(self):
        """Algorithm Input Panel 창을 띄우는 슬롯"""
        if self.algorithm_input_window is None:
            self.algorithm_input_window = AlgorithmInputWindow(self.gps_backend, self)
            self.algorithm_input_window.setAttribute(Qt.WA_DeleteOnClose)
            self.algorithm_input_window.destroyed.connect(self.on_algorithm_input_window_destroyed)
            self.algorithm_input_window.show()
        else:
            self.algorithm_input_window.activateWindow()

    def on_algorithm_input_window_destroyed(self):
        """알고리듬 입력 창이 닫힐 때 변수를 None으로 초기화"""
        self.algorithm_input_window = None

    @Slot()
    def show_index_page(self):
        """Index Page 창을 띄우는 슬롯"""
        if self.index_page_window is None:
            self.index_page_window = IndexPageWindow(self.gps_backend, self)
            self.index_page_window.setAttribute(Qt.WA_DeleteOnClose)
            self.index_page_window.destroyed.connect(self.on_index_page_window_destroyed)
            self.index_page_window.show()
        else:
            self.index_page_window.activateWindow()

    def on_index_page_window_destroyed(self):
        """Index Page 창이 닫힐 때 변수를 None으로 초기화"""
        self.index_page_window = None

    #refac: DockableWidget을 사용할때 gcs_backend같은 python 객체를 같이 넘겨줘야 python객체와 상호작용이 가능
    def setup_dock_widgets(self):
        """도크 위젯들 설정"""
        # 상단 왼쪽 도크
        self.dock_top_left = QDockWidget('카메라', self)
        widget_top_left = DockableWidget('카메라', "src/pages/flight/Camera.qml", self.gps_backend, self.dock_manager)
        self.dock_top_left.setWidget(widget_top_left)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_top_left)

        # 상단 오른쪽 도크
        self.dock_top_right = QDockWidget("PFD", self)
        widget_top_right = DockableWidget("PFD", "src/pages/flight/PFD.qml", self.gps_backend, self.dock_manager)
        self.dock_top_right.setWidget(widget_top_right)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_top_right)

        # 하단 왼쪽 도크
        self.dock_bottom_left = QDockWidget("ND", self)
        widget_bottom_left = DockableWidget("ND", "src/pages/flight/ND.qml", self.gps_backend, self.dock_manager) 
        self.dock_bottom_left.setWidget(widget_bottom_left)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_bottom_left)

        # 하단 오른쪽 도크
        self.dock_bottom_right = QDockWidget("Etc Panels", self)
        widget_bottom_right = DockableWidget(
            "Etc Panels", "src/pages/flight/EtcPanels.qml", self.gps_backend, self.dock_manager)
        self.dock_bottom_right.setWidget(widget_bottom_right)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_bottom_right)

        # 도크 목록 생성
        self.docks = [
            self.dock_top_left,
            self.dock_top_right,
            self.dock_bottom_left,
            self.dock_bottom_right
        ]

        # 도크 위젯들을 4분할로 배치
        # 1단계: 상단 도크들을 좌우로 배치
        self.splitDockWidget(self.dock_top_left, self.dock_top_right, Qt.Horizontal)

        # 2단계: 하단 도크들을 좌우로 배치
        self.splitDockWidget(self.dock_bottom_left, self.dock_bottom_right, Qt.Horizontal)

        # 3단계: 상단과 하단을 상하로 분할 (오른쪽도 함께)
        self.splitDockWidget(self.dock_top_left, self.dock_bottom_left, Qt.Vertical)
        self.splitDockWidget(self.dock_top_right, self.dock_bottom_right, Qt.Vertical)

        # 모든 도크 위젯은 우측 독에만 도킹 가능하게 제한
        for dock in self.docks:
            dock.setAllowedAreas(Qt.RightDockWidgetArea)

        # 도크 위젯 특성 설정
        for dock in self.docks:
            dock.setFeatures(QDockWidget.DockWidgetMovable |
                             QDockWidget.DockWidgetFloatable |
                             QDockWidget.DockWidgetClosable)

    def setup_menu_bar(self):
        """메뉴바 설정"""
        menubar = self.menuBar()
        menubar.setNativeMenuBar(True)  # macOS에서 시스템 메뉴바 허용

        # 보기 메뉴
        view_menu = menubar.addMenu('보기')

        # 레이아웃 복원 액션
        reset_layout_action = view_menu.addAction('레이아웃 복원 (Ctrl+R)')
        reset_layout_action.setShortcut('Ctrl+R')
        reset_layout_action.triggered.connect(self.reset_dock_layout)

        view_menu.addSeparator()

        # 파일 메뉴
        file_menu = menubar.addMenu('파일')

        # 종료 액션
        exit_action = file_menu.addAction('종료 (ESC)')
        exit_action.setShortcut('ESC')
        exit_action.triggered.connect(self.close)

    def toggle_dock_area(self):
        """도크 영역 토글"""
        self.dock_area_visible = not self.dock_area_visible

        for dock in self.docks:
            if self.dock_area_visible:
                dock.show()
                # 도크가 플로팅 상태가 아니라면 다시 도킹
                if dock.isFloating():
                    dock.setFloating(False)
                self.addDockWidget(Qt.RightDockWidgetArea, dock)
            else:
                dock.hide()

        if self.dock_area_visible:
            # 도크 영역이 다시 보일 때 레이아웃 복원
            self.reset_dock_layout()
            # 고정 너비 설정
            self.set_dock_width(self.dock_area_width)

    def set_dock_width(self, width):
        """도크 영역 너비 설정"""
        self.dock_area_width = width

        if self.dock_area_visible:
            # 최소 크기 제한
            for dock in self.docks:
                if dock.widget():
                    dock.widget().setMinimumWidth(200)
                    dock.widget().setMinimumHeight(200)

            # 사분할 배치
            # 상단과 하단 도크들을 각각 조정
            self.resizeDocks(
                [self.dock_top_left, self.dock_top_right],
                [width // 2, width // 2],
                Qt.Horizontal
            )
            self.resizeDocks(
                [self.dock_bottom_left, self.dock_bottom_right],
                [width // 2, width // 2],
                Qt.Horizontal
            )

    def reset_dock_layout(self):
        """도크 레이아웃을 4분할로 복원"""
        if not self.dock_area_visible:
            return

        # 모든 도크 위젯을 다시 표시하고 오른쪽 영역에 추가
        for dock in self.docks:
            if not dock.isVisible():
                dock.show()
            # 플로팅 상태라면 도킹으로 돌리기
            if dock.isFloating():
                dock.setFloating(False)
            self.addDockWidget(Qt.RightDockWidgetArea, dock)

        # 4분할 레이아웃 다시 적용
        self.splitDockWidget(self.dock_top_left, self.dock_top_right, Qt.Horizontal)
        self.splitDockWidget(self.dock_bottom_left, self.dock_bottom_right, Qt.Horizontal)
        self.splitDockWidget(self.dock_top_left, self.dock_bottom_left, Qt.Vertical)
        self.splitDockWidget(self.dock_top_right, self.dock_bottom_right, Qt.Vertical)

        # 너비 설정 적용
        self.set_dock_width(self.dock_area_width)

    def on_resize(self, event):
        """윈도우 크기 변경 시 도크 영역 너비 조정"""
        super().resizeEvent(event)
        if self.dock_area_visible:
            self.dock_area_width = self.width() - 80
            self.set_dock_width(self.dock_area_width)


def main():
    app = QApplication(sys.argv)

    # QML 스타일 설정 (Material)
    os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Material'

    # 폰트 설정
    font_path = resource_path("src/assets/fonts/PretendardVariable.ttf")
    font_id = QFontDatabase.addApplicationFont(font_path)
    if font_id != -1:
        family = QFontDatabase.applicationFontFamilies(font_id)[0]
        app.setFont(QFont(family))
    else:
        print("Pretendard 폰트 설정 실패")
        sys.exit(-1)

    # 메인 윈도우 생성 및 표시
    window = MainWindow()
    window.show()

    # 수동 GPS 입력 윈도우 생성 및 표시
    manual_gps_window = ManualGpsWindow(window.gps_backend)
    manual_gps_window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
