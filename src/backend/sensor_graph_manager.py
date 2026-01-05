from PySide6.QtCore import QObject, Signal, Slot
from .MiniLink.lib.xmlHandler import XmlHandler


class SensorGraphManager(QObject):
    messageUpdated = Signal(dict)  # 메시지 업데이트 시그널

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
