import json
import threading
import serial.tools.list_ports

from PySide6.QtCore import QObject, Signal, Slot

from .lib.MiniLink import MiniLink
from .lib.xmlHandler import XmlHandler


# QML과 통신을 담당할 백엔드 클래스
class InitializePortSelect(QObject):
    connectionResult = Signal(bool, str)  # (성공여부, 메시지)

    connectionSuccessful = Signal(str, int)  # 모니터링 시작을 위한 시그널 (포트, 보드레이트)

    messageMetaDataReady = Signal(str)  # 메시지 메타데이터 전달용 시그널
    messageUpdated = Signal(list)  # 메시지 업데이트 시그널

    def __init__(self, parent=None):
        super().__init__(parent)
        self.port_list = []
        self.monitor_thread = None
        self.monitoring = False

        self.mav = MiniLink()
        self.data_reading_thread = None

    # QML에서 호출할 수 있는 슬롯 (포트 목록 전달)
    @Slot(result=list)
    def get_port_list(self):
        self.port_list.clear()
        ports = serial.tools.list_ports.comports()
        for port in ports:
            self.port_list.append({
                'device': port.device,
                'display': f"{port.device} ({port.description})",
            })

        return self.port_list

    # QML에서 '연결' 버튼을 누르면 호출될 슬롯
    @Slot(str, int)
    def connect_button_clicked(self, device: str, baudrate: int):
        if not device:
            print("오류: 포트가 선택되지 않았습니다.")
            self.connectionResult.emit(False, "포트가 선택되지 않았습니다.")
            return

        print(f"Port: {device}, Baud rate: {baudrate}")

        try:
            # 센서 연결
            self._connect(device, baudrate)
            print(f"{device}에 성공적으로 연결되었습니다.")

            # 데이터 읽기 스레드 시작
            self.data_reading_thread = threading.Thread(target=self._get_sensor_data, daemon=True)
            self.data_reading_thread.start()

            # 연결 성공 시 QML 변화 trigger
            self.connectionResult.emit(True, f"{device} : 연결 성공")

            # GPS 모니터링 시작 시그널 발생
            self.connectionSuccessful.emit(device, baudrate)
        except serial.SerialException as e:
            error_msg = f"시리얼 연결 실패: {str(e)}"
            print(error_msg)
            self.connectionResult.emit(False, error_msg)
        except Exception as e:
            error_msg = f"연결 실패: {str(e)}"
            print(error_msg)
            self.connectionResult.emit(False, error_msg)

    def _connect(self, port: str, baudrate: int):
        """
        센서와 연결을 시도합니다.
        예외가 발생하면 상위 클래스에서 처리하도록 합니다.
        """
        self.port = port
        self.baudrate = baudrate
        self.mav.connect(self.port, self.baudrate)

        # 연결 확인 코드 필요
        # serial.Serial()은 시리얼 포트를 여는 코드일 뿐, 실제로 연결됐는지를 보장하지 않음
        data: list = self.mav.read(enPrint=True, enLog=False)
        if data is False:
            raise serial.SerialException("연결 실패: 데이터 읽기 오류")

    def _get_sensor_data(self):
        """
        센서 데이터를 지속적으로 읽는 메인 루프
        """
        self.mav.chooseMessage(26)

        try:
            while True:
                data: list = self.mav.read(enPrint=True, enLog=False)
                if data:
                    self.messageUpdated.emit(data)
        except Exception as e:
            print("[Monitor] 연결 끊김 감지!")
            # self.connectionResult.emit(False, f"{device} : 연결 끊김, 연결 대기 중...")
            return

    @Slot(int)
    def set_target_message(self, msg_id: int):
        """
        QML에서 호출하여 읽을 메시지 ID를 설정합니다.
        """
        # 그래프를 그릴 메시지 ID를 설정
        self.mav.chooseMessage(msg_id)

        # 해당 메시지의 모든 속성을 가져와서 QML에 전달
        xmlHandler = XmlHandler()
        xmlHandler.loadMessageListFromXML({})
        instance = xmlHandler.getMessageInstance(msg_id)
        fields = [field.attrib for field in instance.findall("field")]
        for field in fields:
            field['plot'] = True  # QML에서 플롯팅 여부
            if 'units' not in field:
                field['units'] = ''

        meta_data = {
            'id': msg_id,
            'name': instance.get("name"),
            'description': instance.find("description").text,
            'fields': fields
        }

        # 시그널로 데이터 전달
        print(f"메시지 메타데이터 준비 완료: {meta_data}")
        self.messageMetaDataReady.emit(json.dumps(meta_data))

    @Slot(result=list)
    def get_message_list(self):
        """
        현재 연결된 센서의 메시지 목록을 반환합니다.
        """
        message_list = []
        for key, value in self.mav.getMessageList().items():
            message_list.append({
                'id': key,
                'name': value[0]
            })

        return message_list
