from PySide6.QtCore import QObject, Signal, Slot, QTimer
import time
class FlightStatusManager(QObject):
    """
    드론 비행 상태 데이터를 처리하고 QML과 통신하는 컨트롤러

    처리 메시지:
      - ID   0: HEARTBEAT          → heartbeatReceived
      - ID   1: SYS_STATUS         → batteryChanged
      - ID  36: SERVO_OUTPUT_RAW   → motorValuesChanged
      - ID 245: EXTENDED_SYS_STATE → systemStateChanged
    """

    # HEARTBEAT (ID 0)
    heartbeatReceived = Signal(bool, int, int)   # isArmed, base_mode, custom_mode

    # SYS_STATUS (ID 1)
    batteryChanged = Signal(float, float, int)   # voltage(V), current(A), remaining(%)

    # SERVO_OUTPUT_RAW (ID 36)
    motorValuesChanged = Signal(int, int, int, int)  # servo1~4 raw (1000~2000 us)

    # EXTENDED_SYS_STATE (ID 245)
    systemStateChanged = Signal(int, int)        # vtol_state, landed_state

    # Flight time tracking
    flightTimeChanged = Signal(int)              # elapsed flight time in seconds

    _TARGET_IDS = {0, 1, 36, 245}

    def __init__(self, parent=None):
        super().__init__(parent)
        self._is_flying = False
        self._takeoff_time = 0
        self._flight_time = 0

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._update_flight_time)
        self._timer.start(1000)

    def _update_flight_time(self):
        if self._is_flying:
            self._flight_time = int(time.time() - self._takeoff_time)
            self.flightTimeChanged.emit(self._flight_time)

    @Slot(int, dict)
    def get_data(self, msg_id: int, data: dict):
        if msg_id not in self._TARGET_IDS:
            return

        if msg_id == 0:   # HEARTBEAT
            base_mode   = data.get("base_mode", 0)
            custom_mode = data.get("custom_mode", 0)
            is_armed    = bool(base_mode & 128)
            self.heartbeatReceived.emit(is_armed, base_mode, custom_mode)

        elif msg_id == 1:  # SYS_STATUS
            voltage   = data.get("voltage_battery", 0) / 1000.0  # mV → V
            current   = data.get("current_battery", 0) / 100.0   # cA → A
            remaining = max(0, min(100, data.get("battery_remaining", 0)))
            self.batteryChanged.emit(voltage, current, remaining)

        elif msg_id == 36:  # SERVO_OUTPUT_RAW
            self.motorValuesChanged.emit(
                data.get("servo1_raw", 0),
                data.get("servo2_raw", 0),
                data.get("servo3_raw", 0),
                data.get("servo4_raw", 0),
            )

        elif msg_id == 245:  # EXTENDED_SYS_STATE
            landed_state = data.get("landed_state", 0)
            self.systemStateChanged.emit(
                data.get("vtol_state",   0),
                landed_state,
            )
            
            # Flight time tracking based on landed_state
            # 1: On Ground, 2: In Air, 3: Takeoff, 4: Landing
            if landed_state in (2, 3, 4):
                if not self._is_flying:
                    self._is_flying = True
                    self._takeoff_time = time.time()
                    self._flight_time = 0
            elif landed_state == 1:
                if self._is_flying:
                    self._is_flying = False
                    self.flightTimeChanged.emit(self._flight_time)
