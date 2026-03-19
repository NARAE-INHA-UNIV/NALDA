from PySide6.QtCore import QObject, Signal, Slot


_MAV_SEVERITY = {
    0: "EMERGENCY",
    1: "ALERT",
    2: "CRITICAL",
    3: "ERROR",
    4: "WARNING",
}


class StatusTextManager(QObject):
    """
    MAVLink STATUSTEXT (#253) 메시지 처리 클래스
    severity 0~4 (EMERGENCY~WARNING)만 QML로 전달
    """

    statusTextReceived = Signal(str, str)  # severity_name, text

    @Slot(int, dict)
    def get_data(self, msg_id: int, msg: dict):
        if msg_id != 253:
            return
        print(f"Received STATUSTEXT: {msg}")

        severity = msg.get("severity", 6)
        # if severity > 4:
        #     return

        text = msg.get("text", "").replace("\x00", "").strip()
        severity_name = _MAV_SEVERITY.get(severity, "UNKNOWN")
        self.statusTextReceived.emit(severity_name, text)
