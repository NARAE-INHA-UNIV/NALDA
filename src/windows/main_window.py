from PySide6.QtCore import QUrl, Qt
from PySide6.QtWidgets import QMainWindow, QDockWidget, QWidget, QVBoxLayout
from PySide6.QtQuickWidgets import QQuickWidget
from PySide6.QtGui import QKeySequence, QShortcut

from backend.sensor_graph_manager import SensorGraphManager
from backend.attitude_overview_manger import AttitudeOverviewManager
from backend.tooltip_manager import TooltipManager
from backend.serial_manager import SerialManager
from backend.dock_manager import DockManager
from backend.gps_manager import GpsManager
from backend.resource_manager import ResourceManager
from backend.pfd_maganer import PFDManager
from backend.parameter_setting_manager import ParameterSettingManager

from backend.utils import resource_path


class DockableWidget(QWidget):
    """도킹 가능한 위젯 클래스"""

    def __init__(self, title: str, qml_path: str, managers: list):
        super().__init__()
        self.setWindowTitle(title)

        layout = QVBoxLayout(self)
        self.qml_widget = QQuickWidget()

        # QML 소스를 로드하기 전에 컨텍스트를 먼저 설정
        # 메인 윈도우에서 등록된 벡엑드 리소스를 등록
        context = self.qml_widget.rootContext()
        for manager_name, manager in managers:
            context.setContextProperty(manager_name, manager)

        # qml 소스 등록
        self.qml_widget.setSource(QUrl.fromLocalFile(resource_path(qml_path)))
        self.qml_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)

        layout.addWidget(self.qml_widget)


class MainWindow(QMainWindow):

    def __init__(self):
        super().__init__()

        # 제목 설정
        self.setWindowTitle("NALDA")

        # 스타일시트 로드
        self._load_stylesheet()

        # 중앙 위젯 설정
        self._setup_central_widget()

        # 단축키 설정
        self._setup_shortcuts()

        # 윈도우 크기 변경 이벤트 설정
        self.resizeEvent = self._on_resize

        # 도크 위젯들 생성
        self._setup_dock_widgets()

        # 도크 영역 초기 상태 설정
        self.dock_area_visible = True
        self.dock_area_width = self.width() - 80
        self._set_dock_width(self.dock_area_width)

        # 최소 크기 설정
        self.setMinimumSize(1280, 720)

        # 전체화면으로 변경
        # 마지막에 호출해야 레이아웃이 제대로 적용됨
        self.showMaximized()

    def _load_stylesheet(self):
        """스타일시트 파일 로드"""
        try:
            stylesheet_path = resource_path("frontend/styles.qss")
            with open(stylesheet_path, 'r', encoding='utf-8') as file:
                stylesheet = file.read()
                self.setStyleSheet(stylesheet)
        except FileNotFoundError:
            print(f"스타일시트 파일을 찾을 수 없습니다:")
        except Exception as e:
            print(f"스타일시트 로드 중 오류 발생: {e}")

    def _setup_central_widget(self):
        """중앙 위젯 설정"""

        # QML 컨텍스트
        self.tooltip_manager = TooltipManager()
        self.dock_manager = DockManager(self)
        self.serial_manager = SerialManager()
        self.gps_manager = GpsManager()
        self.sensor_graph_manager = SensorGraphManager()
        self.attitude_overview_manager = AttitudeOverviewManager()
        self.resource_manager = ResourceManager()
        self.parameter_setting_manager = ParameterSettingManager()

        # 독 전용 컨텍스트
        self.pfd_manager = PFDManager()

        # serial 데이터 업데이트 이벤트 등록
        self.serial_manager.messageUpdated.connect(self.sensor_graph_manager.get_data)
        self.serial_manager.messageUpdated.connect(self.attitude_overview_manager.get_data)
        self.serial_manager.messageUpdated.connect(self.pfd_manager.get_data)
        # self.serial_manager.messageUpdated.connect(self.gps_backend.get_data) # gps도 연결 필요

        # send 이벤트
        self.attitude_overview_manager.newPidGains.connect(self.serial_manager.send_message)

        # 위젯 생성
        central_widget = QQuickWidget()
        context = central_widget.rootContext()
        engine = central_widget.engine()

        # 벡엔드 연결
        context.setContextProperty("tooltipManager", self.tooltip_manager)
        context.setContextProperty("dockManager", self.dock_manager)
        context.setContextProperty("serialManager", self.serial_manager)
        context.setContextProperty("gpsManager", self.gps_manager)
        context.setContextProperty("sensorGraphManager", self.sensor_graph_manager)
        context.setContextProperty("attitudeOverviewManager", self.attitude_overview_manager)
        context.setContextProperty("resourceManager", self.resource_manager)
        context.setContextProperty("parameterSettingManager", self.parameter_setting_manager)
        context.setContextProperty("yourTreeModel", self.parameter_setting_manager.tree_model)

        # 전역 스타일 설정
        frontend_path = resource_path("frontend")
        engine.addImportPath(frontend_path)

        # main.qml 설정
        qml_file = resource_path("frontend/main.qml")
        central_widget.setSource(QUrl.fromLocalFile(qml_file))
        central_widget.setResizeMode(QQuickWidget.SizeRootObjectToView)
        self.setCentralWidget(central_widget)

    def _setup_shortcuts(self):
        """단축키만 설정"""

        # Ctrl+R로 레이아웃 복원
        reset_shortcut = QShortcut(QKeySequence('Ctrl+R'), self)
        reset_shortcut.activated.connect(self._reset_dock_layout)

        # ESC로 종료
        exit_shortcut = QShortcut(QKeySequence('ESC'), self)
        exit_shortcut.activated.connect(self.close)

    def _on_resize(self, event):
        """윈도우 크기 변경 시 도크 영역 너비 조정"""
        super().resizeEvent(event)
        if self.dock_area_visible:
            self.dock_area_width = self.width() - 80
            self._set_dock_width(self.dock_area_width)

    def _setup_dock_widgets(self):
        """도크 위젯들 설정"""

        # 상단 왼쪽 도크
        self.dock_top_left = QDockWidget('카메라', self)
        widget_top_left = DockableWidget(
            title='카메라',
            qml_path='frontend/pages/flight/camera/index.qml',
            managers=[]
        )
        self.dock_top_left.setWidget(widget_top_left)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_top_left)

        # 상단 오른쪽 도크
        self.dock_top_right = QDockWidget('PFD', self)
        widget_top_right = DockableWidget(
            title='PFD',
            qml_path='frontend/pages/flight/pfd/index.qml',
            managers=[
                ('pfdManager', self.pfd_manager),
            ]
        )
        self.dock_top_right.setWidget(widget_top_right)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_top_right)

        # 하단 왼쪽 도크
        self.dock_bottom_left = QDockWidget('ND', self)
        widget_bottom_left = DockableWidget(
            title='ND',
            qml_path='frontend/pages/flight/nd/index.qml',
            managers=[
                ('resourceManager', self.resource_manager),
                ('gpsManager', self.gps_manager),
            ]
        )
        self.dock_bottom_left.setWidget(widget_bottom_left)
        self.addDockWidget(Qt.RightDockWidgetArea, self.dock_bottom_left)

        # 하단 오른쪽 도크
        self.dock_bottom_right = QDockWidget('Etc Panels', self)
        widget_bottom_right = DockableWidget(
            title='Etc Panels',
            qml_path='frontend/pages/flight/etc-panels/index.qml',
            managers=[
                ('gpsManager', self.gps_manager),
            ]
        )
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

        # 도크 위젯 설정
        for dock in self.docks:
            # 모든 도크 위젯은 우측 독에만 도킹 가능하게 제한
            dock.setAllowedAreas(Qt.RightDockWidgetArea)

            # 도크 위젯 특성 설정
            dock.setFeatures(QDockWidget.DockWidgetMovable |
                             QDockWidget.DockWidgetFloatable |
                             QDockWidget.DockWidgetClosable)

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
            self._reset_dock_layout()
            # 고정 너비 설정
            self._set_dock_width(self.dock_area_width)

    def _set_dock_width(self, width):
        """도크 영역 너비 설정"""
        self.dock_area_width = width

        if self.dock_area_visible:
            # 최소 크기 제한
            for dock in self.docks:
                if dock.widget():
                    dock.widget().setMinimumWidth(100)
                    dock.widget().setMinimumHeight(100)

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

    def _reset_dock_layout(self):
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
        self._set_dock_width(self.dock_area_width)
