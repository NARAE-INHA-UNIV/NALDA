import os
from dotenv import load_dotenv
from PySide6.QtCore import QObject, Signal, Slot, Property
# from PySide6.QtPositioning import QGeoCoordinate

# from windows.location_history_window import LocationHistoryWindow
# from windows.manual_gps_window import ManualGpsWindow

# .env 파일 로드
load_dotenv()


class GpsManager(QObject):
    """
    GPS 백엔드 
    """

    # # GPS 데이터 변경 시그널 정의 (실시간 위치 정보 변경에대한 시그널 - 경로점 기록시 사용)
    # gpsDataChanged = Signal(float, float, float, float)

    gpsCoordinateChanged = Signal(float, float, float, float)
    gpsStatusChanged = Signal(int, float)

    def __init__(self, parent=None):
        super().__init__(parent)
        # # Location History 창을 관리하기 위한 변수
        # self.history_window = LocationHistoryWindow(self)
        # self.history_window.hide()

        # # 수동 GPS 입력 창을 관리하기 위한 변수
        # self.manual_gps_window = ManualGpsWindow(self)
        # # self.manual_gps_window.show()
        # self.manual_gps_window.hide()

        self.target_message_ids = [
            24,  # GPS_RAW_INT
            33,  # GLOBAL_POSITION_INT
        ]

    @Slot(int, dict)
    def get_data(self, message_id: int, data: dict):
        """
        SerialManager에 메시지가 전달되면 호출되는 슬롯
        """
        if message_id in self.target_message_ids:
            if message_id == 24:  # GPS_RAW_INT
                satellites_visible = data.get('satellites_visible', 0)
                hdop = data.get('eph', 0) / 100.0  # eph는 cm 단위이므로 m 단위로 변환
                self.gpsStatusChanged.emit(satellites_visible, hdop)
            elif message_id == 33:  # GLOBAL_POSITION_INT
                lat = data.get('lat', 0) / 1e7  # 1e7로 나누어 도 단위로 변환
                lon = data.get('lon', 0) / 1e7
                alt = data.get('alt', 0) / 1000.0  # alt는 mm 단위이므로 m 단위로 변환
                hdg = data.get('hdg', 0) / 100.0  # hdg는 센티도 단위이므로 도 단위로 변환
                self.gpsCoordinateChanged.emit(lat, lon, alt, hdg)

    @Slot(result=str)
    def getOSMApiKey(self):
        return os.getenv('OSM_API_KEY', '')
