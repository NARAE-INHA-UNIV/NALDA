import time

from PySide6.QtCore import QObject, Signal, Slot
from .MiniLink.lib.xmlHandler import XmlHandler


class AttitudeOverviewManager(QObject):
    messageUpdated = Signal(dict)  # 메시지 업데이트 시그널
    newPidGains = Signal(int, list, bool)     # 새로운 PID 게인 시그널

    def __init__(self):
        super().__init__()
        self.current_message_id = None
        self.message_data = {}

        self.xmlHandler = XmlHandler()
        self.xmlHandler.loadMessageListFromXML({})

    @Slot(int, dict)
    def get_data(self, message_id: int, data: dict):
        """
        SerialManager에 메시지가 전달되면 호출되는 슬롯
        """
        if message_id == self.current_message_id:
            self.message_data = data
            self.messageUpdated.emit(data)

    @Slot(int, result=dict)
    def setTargetMessage(self, message_id: int):
        self.current_message_id = message_id

        # 해당 메시지의 모든 속성을 가져와서 QML에 전달
        instance = self.xmlHandler.getMessageInstance(message_id)
        fields = [field.attrib for field in instance.findall("field")]
        for field in fields:
            field['plot'] = True  # QML에서 플롯팅 여부
            if 'units' not in field:
                field['units'] = ''

        meta_data = {
            'id': message_id,
            'name': instance.get("name"),
            'description': instance.find("description").text,
            'fields': fields
        }
        return meta_data

    @Slot(dict)
    def sendPidValues(self, pid_gains: dict):
        # print(f'pid gains: {pid_gains}')
        angle_gains = [
            pid_gains['angle']['roll']['p'], pid_gains['angle']['roll']['i'], pid_gains['angle']['roll']['d'],
            pid_gains['angle']['pitch']['p'], pid_gains['angle']['pitch']['i'], pid_gains['angle']['pitch']['d'],
            pid_gains['angle']['yaw']['p'], pid_gains['angle']['yaw']['i'], pid_gains['angle']['yaw']['d'],
        ]
        rate_gains = [
            pid_gains['rate']['roll']['p'], pid_gains['rate']['roll']['i'], pid_gains['rate']['roll']['d'],
            pid_gains['rate']['pitch']['p'], pid_gains['rate']['pitch']['i'], pid_gains['rate']['pitch']['d'],
            pid_gains['rate']['yaw']['p'], pid_gains['rate']['yaw']['i'], pid_gains['rate']['yaw']['d'],
        ]
        # print(f'angle gains: {angle_gains}')
        # print(f'rate gains: {rate_gains}')
        self.newPidGains.emit(250, angle_gains, True)
        time.sleep(0.1)
        self.newPidGains.emit(251, rate_gains, True)
