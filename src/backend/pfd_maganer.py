import math
from PySide6.QtCore import QObject, Signal, QTimer, Slot
# from PySide6.QtQml import QmlElement

# QML_IMPORT_NAME = "PFDController"
# QML_IMPORT_MAJOR_VERSION = 1


# @QmlElement
class PFDManager(QObject):
    """
    PFD (Primary Flight Display) 데이터를 처리하고 QML과 통신하는 컨트롤러
    """

    # QML로 데이터를 전송하는 시그널들
    pitchAngleChanged = Signal(float)
    rollAngleChanged = Signal(float)
    altitudeChanged = Signal(float)
    airspeedChanged = Signal(float)
    headingChanged = Signal(float)

    def __init__(self):
        super().__init__()

        # 현재 비행 데이터
        self._pitch_angle = 0.0      # 피치 각도 (도)
        self._roll_angle = 0.0       # 롤 각도 (도)
        self._altitude = 0.0         # 고도 (미터)
        self._airspeed = 0.0         # 대기속도 (노트)
        self._heading = 0.0          # 방위각 (도)

        # 시뮬레이션 타이머
        self._simulation_timer = QTimer()
        self._simulation_timer.timeout.connect(self._update_simulation)
        self._simulation_timer.start(50)  # 20 FPS

        # 시뮬레이션 상태
        self._simulation_active = False
        self._simulation_time = 0.0

    @Slot(int, dict)
    def get_data(self, message_id: int, data: dict):
        """
        SerialManager에 메시지가 전달되면 호출되는 슬롯
        """
        # if message_id == self.current_message_id:
        #     self.message_data = data
        #     self.messageUpdated.emit(data)
        pass

    @property
    def pitch_angle(self):
        return self._pitch_angle

    @pitch_angle.setter
    def pitch_angle(self, value):
        if self._pitch_angle != value:
            self._pitch_angle = value
            self.pitchAngleChanged.emit(value)

    @property
    def roll_angle(self):
        return self._roll_angle

    @roll_angle.setter
    def roll_angle(self, value):
        if self._roll_angle != value:
            self._roll_angle = value
            self.rollAngleChanged.emit(value)

    @property
    def altitude(self):
        return self._altitude

    @altitude.setter
    def altitude(self, value):
        if self._altitude != value:
            self._altitude = value
            self.altitudeChanged.emit(value)

    @property
    def airspeed(self):
        return self._airspeed

    @airspeed.setter
    def airspeed(self, value):
        if self._airspeed != value:
            self._airspeed = value
            self.airspeedChanged.emit(value)

    @property
    def heading(self):
        return self._heading

    @heading.setter
    def heading(self, value):
        if self._heading != value:
            self._heading = value
            self.headingChanged.emit(value)

    def start_simulation(self):
        """시뮬레이션 시작"""
        self._simulation_active = True
        self._simulation_time = 0.0
        print("PFD 시뮬레이션 시작")

    def stop_simulation(self):
        """시뮬레이션 중지"""
        self._simulation_active = False
        print("PFD 시뮬레이션 중지")

    def reset_display(self):
        """디스플레이 초기화"""
        self.pitch_angle = 0.0
        self.roll_angle = 0.0
        self.altitude = 0.0
        self.airspeed = 0.0
        self.heading = 0.0
        print("PFD 디스플레이 초기화")

    def update_flight_data(self, pitch, roll, altitude, airspeed, heading=None):
        """실제 비행 데이터 업데이트"""
        self.pitch_angle = pitch
        self.roll_angle = roll
        self.altitude = altitude
        self.airspeed = airspeed
        if heading is not None:
            self.heading = heading

    def _update_simulation(self):
        """시뮬레이션 데이터 업데이트"""
        if not self._simulation_active:
            return

        self._simulation_time += 0.05  # 50ms 간격

        # 사인파를 이용한 시뮬레이션
        # 피치 각도: -15도 ~ +15도 범위에서 사인파
        pitch = 15 * math.sin(self._simulation_time * 0.5)

        # 롤 각도: -30도 ~ +30도 범위에서 사인파 (다른 주기)
        roll = 30 * math.sin(self._simulation_time * 0.3)

        # 고도: 점진적 증가 + 약간의 변동
        altitude = 100 + 50 * math.sin(self._simulation_time * 0.2)

        # 대기속도: 기본 속도 + 약간의 변동
        airspeed = 80 + 10 * math.sin(self._simulation_time * 0.4)

        # 방위각: 0~360도 범위에서 점진적 변화
        heading = (self._simulation_time * 5) % 360

        # 데이터 업데이트
        self.update_flight_data(pitch, roll, altitude, airspeed, heading)

    # QML에서 호출할 수 있는 메서드들
    @Slot(float)
    def setPitchAngle(self, angle):
        """피치 각도 설정 (QML에서 호출)"""
        self.pitch_angle = float(angle)

    @Slot(float)
    def setRollAngle(self, angle):
        """롤 각도 설정 (QML에서 호출)"""
        self.roll_angle = float(angle)

    @Slot(float)
    def setAltitude(self, altitude):
        """고도 설정 (QML에서 호출)"""
        self.altitude = float(altitude)

    @Slot(float)
    def setAirspeed(self, airspeed):
        """대기속도 설정 (QML에서 호출)"""
        self.airspeed = float(airspeed)

    @Slot(float)
    def setHeading(self, heading):
        """방위각 설정 (QML에서 호출)"""
        self.heading = float(heading)

    @Slot()
    def toggleSimulation(self):
        """시뮬레이션 토글 (QML에서 호출)"""
        if self._simulation_active:
            self.stop_simulation()
        else:
            self.start_simulation()

    @Slot()
    def resetDisplay(self):
        """디스플레이 리셋 (QML에서 호출)"""
        self.reset_display()
