# 모든 backend작업 총괄을 여기서 진행
import time
from datetime import datetime  # 시간 기록을 위해 추가

from PySide6.QtCore import QObject, Signal, Slot, QThread, Property, Qt
from PySide6.QtPositioning import QGeoCoordinate

from windows.location_history_window import LocationHistoryWindow
from windows.manual_gps_window import ManualGpsWindow


class GpsManager(QObject):
    """
    GCS 백엔드 클래스
     - 시리얼 포트에서 GPS 데이터를 읽어 QML로 전송
     - QML에서 받은 데이터를 FC로 전송
    """
    # GPS 데이터 변경 시그널 정의 (실시간 위치 정보 변경에대한 시그널 - 경로점 기록시 사용)
    gpsDataChanged = Signal(float, float, float, float)
    # 경로 데이터 변경 시그널 정의  (누적 위치 정보 변경에대한 시그널 - 경로점 이을때 사용)
    pathDataChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.gps_reader = None
        self.monitoring_thread = None
        self._path_data = []  # 경로 데이터를 저장할 리스트 (구조 변경)

        # 초기 인하대 좌표를 경로에 추가
        self.add_path_point(37.450767, 126.657016, 0, 0)
        self.pathDataChanged.emit()  # 초기 경로 데이터 변경 알림

        # Location History 창을 관리하기 위한 변수
        self.history_window = LocationHistoryWindow(self)
        self.history_window.hide()

        # 수동 GPS 입력 창을 관리하기 위한 변수
        self.manual_gps_window = ManualGpsWindow(self)
        # self.manual_gps_window.show()
        self.manual_gps_window.hide()

    # QML에서 지도 표시에 사용할 좌표 리스트를 위한 프로퍼티

    @Property(list, notify=pathDataChanged)
    def pathCoordinates(self):
        return [item['coordinate'] for item in self._path_data]

    # QML의 History 창에서 사용할 전체 데이터 리스트를 위한 프로퍼티
    @Property(list, notify=pathDataChanged)
    def pathData(self):
        return self._path_data

    def add_path_point(self, lat, lon, alt, hdg):
        """경로 지점을 상세 정보와 함께 추가하는 헬퍼 함수"""
        new_point = {
            'timestamp': datetime.now().strftime("%H:%M:%S"),
            'lat': round(lat, 7),
            'lon': round(lon, 7),
            'alt': round(alt, 2),
            'hdg': round(hdg, 2),
            'coordinate': QGeoCoordinate(lat, lon, alt)
        }
        self._path_data.append(new_point)

    # @Slot(str, int)
    # def start_gps_monitoring(self, port, baudrate):
    #     """
    #     GPS 데이터 모니터링 시작
    #      - 새로운 스레드에서 GPS 데이터를 계속 읽어옴
    #     """
    #     if self.monitoring_thread and self.monitoring_thread.isRunning():
    #         print("모니터링이 이미 실행 중입니다.")
    #         return

    #     self.gps_reader = MAVLink(port, baudrate)
    #     self.monitoring_thread = QThread()
    #     self.gps_reader.moveToThread(self.monitoring_thread)

    #     # 스레드가 시작될 때 run_monitoring 실행
    #     self.monitoring_thread.started.connect(self.run_monitoring)

    #     self.monitoring_thread.start()
    #     print(f"{port}에서 GPS 데이터 모니터링 시작...")

    # def run_monitoring(self):
    #     """
    #     실제 GPS 데이터를 읽고 시그널을 발생시키는 메서드
    #     """
    #     while self.monitoring_thread and self.monitoring_thread.isRunning():
    #         if self.gps_reader.getData():  # getData()가 성공적으로 데이터를 읽고 파싱했을 때
    #             lat = self.gps_reader.lat
    #             lon = self.gps_reader.lon
    #             alt = self.gps_reader.alt
    #             hdg = self.gps_reader.hdg

    #             self.gpsDataChanged.emit(lat, lon, alt, hdg)

    #             # 경로 데이터에 추가
    #             self.add_path_point(lat, lon, alt, hdg)
    #             self.pathDataChanged.emit()  # 경로 데이터 변경 알림

    #         time.sleep(0.1)  # 0.1초 간격으로 데이터 확인

    # @Slot()
    # def stop_gps_monitoring(self):
    #     """
    #     GPS 데이터 모니터링 중지
    #     """
    #     if self.monitoring_thread and self.monitoring_thread.isRunning():
    #         self.monitoring_thread.quit()
    #         self.monitoring_thread.wait()
    #         self.monitoring_thread = None
    #         print("GPS 데이터 모니터링 중지.")
    #     else:
    #         print("모니터링이 실행 중이지 않습니다.")

    @Slot(float, float, float, float)
    def updateGpsManual(self, lat: float, lon: float, alt: float, hdg: float):
        """
        QML에서 수동으로 GPS 데이터를 업데이트하는 슬롯
        """
        print(f"Manual GPS Update: Lat={lat}, Lon={lon}, Alt={alt}, Hdg={hdg}")
        self.gpsDataChanged.emit(lat, lon, alt, hdg)

        # 경로 데이터에 추가
        self.add_path_point(lat, lon, alt, hdg)
        self.pathDataChanged.emit()  # 경로 데이터 변경 알림

    @Slot()
    def clearPath(self):
        """
        경로 데이터를 초기화하는 슬롯
        """
        self._path_data.clear()
        # 경로 초기화 후 초기점 다시 추가
        self.add_path_point(37.450767, 126.657016, 0, 0)
        self.pathDataChanged.emit()
        print("GPS path cleared.")

    @Slot()
    def showLocationHistory(self):
        """Location History 창을 띄우는 슬롯"""
        self.history_window.show()

    # QML에서 직접 GPS 데이터를 가져갈 수 있도록 하는 슬롯들
    @Slot(result=float)
    def getLatitude(self):
        return self.gps_reader.lat if self.gps_reader else 0.0

    @Slot(result=float)
    def getLongitude(self):
        return self.gps_reader.lon if self.gps_reader else 0.0

    @Slot(result=float)
    def getAltitude(self):
        return self.gps_reader.alt if self.gps_reader else 0.0

    @Slot(result=float)
    def getHeading(self):
        return self.gps_reader.hdg if self.gps_reader else 0.0
