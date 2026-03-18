import math

from PySide6.QtCore import QObject, Signal, Slot


def _safe(value, default=0.0):
    """None 또는 NaN 값을 default로 대체 (원래 QML의 `value || 0` 동작과 동일)"""
    try:
        v = float(value)
        return default if math.isnan(v) else v
    except (TypeError, ValueError):
        return default


class PFDManager(QObject):
    """
    PFD (Primary Flight Display) 데이터를 처리하고 QML과 통신하는 컨트롤러
    """

    pitchAngleChanged    = Signal(float)  # msg 30: ATTITUDE
    rollAngleChanged     = Signal(float)  # msg 30: ATTITUDE
    altitudeChanged      = Signal(float)  # msg 74: VFR_HUD / msg 33: GLOBAL_POSITION_INT
    airspeedChanged      = Signal(float)  # msg 74: VFR_HUD
    groundspeedChanged   = Signal(float)  # msg 74: VFR_HUD
    headingChanged       = Signal(float)  # msg 74: VFR_HUD
    vspdChanged          = Signal(float)  # msg 74: VFR_HUD / msg 33: GLOBAL_POSITION_INT
    fixTypeChanged       = Signal(int)    # msg 24: GPS_RAW_INT

    def __init__(self):
        super().__init__()

    @Slot(int, dict)
    def get_data(self, message_id: int, data: dict):
        if message_id == 30:   # ATTITUDE
            self.pitchAngleChanged.emit(_safe(data.get("pitch")))
            self.rollAngleChanged.emit(_safe(data.get("roll")))

        elif message_id == 74:  # VFR_HUD
            self.airspeedChanged.emit(_safe(data.get("airspeed")))
            self.groundspeedChanged.emit(_safe(data.get("groundspeed")))
            self.headingChanged.emit(_safe(data.get("heading")))
            self.altitudeChanged.emit(_safe(data.get("alt")))
            self.vspdChanged.emit(_safe(data.get("climb")))

        elif message_id == 33:  # GLOBAL_POSITION_INT
            # alt: mm → m
            if "alt" in data:
                self.altitudeChanged.emit(_safe(data["alt"]) / 1000.0)
            # vz: cm/s → m/s, 음수=상승 / 양수=하강
            if "vz" in data:
                self.vspdChanged.emit(-_safe(data["vz"]) / 100.0)

        elif message_id == 24:  # GPS_RAW_INT
            self.fixTypeChanged.emit(int(_safe(data.get("fix_type"), default=0)))
