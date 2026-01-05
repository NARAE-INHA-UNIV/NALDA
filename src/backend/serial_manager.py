import time
import struct
import threading
import serial.tools.list_ports

from PySide6.QtCore import QObject, Signal, Slot

from .MiniLink.MiniLink import MiniLink
from .MiniLink.lib.xmlHandler import XmlHandler


class SerialManager(QObject):
    """
    QML과 통신을 담당할 백엔드 클래스
    """

    messageUpdated = Signal(int, dict)  # 메시지 업데이트 시그널

    def __init__(self, parent=None):
        super().__init__(parent)
        self.port = None      # 현재 연결된 포트
        self.baudrate = None  # 현재 연결된 보드레이트

        self.mav = MiniLink()
        self.data_reading_thread = None
        self.data_reading_thread_stop_flag = threading.Event()

        self.xmlHandler = XmlHandler()
        self.xmlHandler.loadMessageListFromXML({})
        self.message_list = []
        self.latest_data = {}

    @Slot(result=list)
    def getPortList(self):
        """
        QML에서 호출할 수 있는 슬롯 (포트 목록 전달)
        """

        port_list = []
        for port in serial.tools.list_ports.comports():
            port_list.append({
                'device': port.device,
                'description': port.description,
            })

        return port_list

    @Slot(str, int, result=bool)
    def connectSerial(self, device: str, baudrate: int):
        """
        QML에서 연결 버튼을 누르면 호출될 슬롯
        """

        if not device or not baudrate:
            print("오류: 포트 혹은 보율이 선택되지 않았습니다.")
            return False
        if self.port is not None or self.baudrate is not None:
            print("이미 연결된 포트가 있습니다.")
            return False

        try:
            # 센서 연결
            self._connect(device, baudrate)
            print(f"{device}에 성공적으로 연결되었습니다.")

            # 연결된 포트와 보드레이트 저장
            self.port = device
            self.baudrate = baudrate

            # 메시지 목록 가져오기
            self.message_list = self.getMessageList()

            # 데이터 읽기 스레드 시작
            self.data_reading_thread_stop_flag = threading.Event()
            self.data_reading_thread = threading.Thread(target=self._get_sensor_data, daemon=True)
            self.data_reading_thread.start()

            return True
        except serial.SerialException as e:
            error_msg = f"시리얼 연결 실패: {str(e)}"
            print(error_msg)
            return False
        except Exception as e:
            error_msg = f"연결 실패: {str(e)}"
            print(error_msg)
            return False

    @Slot(result=bool)
    def disconnectSerial(self):
        """
        시리얼 연결 해제 슬롯
        """

        # 스레드 종료를 위한 이벤트 설정
        self.data_reading_thread_stop_flag.set()

        # 스레드 종료 대기
        self.data_reading_thread.join()

        # 시리얼 연결 해제
        res = self.mav.disconnect()
        if res:
            self.port = None
            self.baudrate = None
            print("시리얼 연결이 해제되었습니다.")
            return True
        else:
            print("시리얼 연결 해제에 실패했습니다.")
            return False

    def _connect(self, port: str, baudrate: int):
        """
        센서와 연결을 시도합니다.
        예외가 발생하면 상위 클래스에서 처리하도록 합니다.
        """

        self.mav.connect(port, baudrate)

        # 연결 확인 코드
        # self.mav.connect() 내부의 serial.Serial()은 시리얼 포트를 여는 코드일 뿐, 실제로 연결됐는지를 보장하지 않음
        # 따라서, 연결 후 3초 동안 데이터 수신이 없으면 연결 실패로 간주
        self.mav.chooseMessage(26)
        start_time = time.time()
        while True:
            data: list = self.mav.read(enPrint=True, enLog=False)
            if data:
                print("연결 성공")
                break
            if time.time() - start_time > 2:  # 2초 동안 데이터가 없으면 연결 실패로 간주
                print("연결 실패")
                raise serial.SerialException("연결 실패: 데이터 수신 대기 시간 초과")

    def _get_sensor_data(self):
        """
        센서 데이터를 지속적으로 읽는 메인 루프
        """

        try:
            message_id_list = [msg['id'] for msg in self.message_list]
            message_frame = {msg['id']: msg['fields'] for msg in self.message_list}

            current_message_idx = 0
            msg_id = message_id_list[current_message_idx]
            self.mav.chooseMessage(msg_id)
            while not self.data_reading_thread_stop_flag.is_set():
                data: list = self.mav.read(enPrint=False, enLog=False)
                if data:
                    # 데이터 맵핑
                    msg = {}
                    for key, value in zip(message_frame[msg_id], data):
                        msg[key] = value
                    self.latest_data[msg_id] = msg

                    self.messageUpdated.emit(msg_id, msg)

                    # 다음 메시지 선택
                    current_message_idx = (current_message_idx + 1) % len(message_id_list)
                    msg_id = message_id_list[current_message_idx]
                    self.mav.chooseMessage(msg_id)
                    # print(f"Latest data: {self.latest_data}")
        except Exception as e:
            print("[Monitor] 연결 끊김 감지!")
            self.port = None
            self.baudrate = None
            return

    @Slot(result=dict)
    def getCurrentConnection(self):
        """
        현재 연결된 시리얼 포트 정보를 반환합니다.
        """

        return {
            'port': self.port,
            'baudrate': self.baudrate
        }

    @Slot(result=list)
    def getMessageList(self):
        """
        현재 연결된 센서의 메시지 목록을 반환합니다.
        """

        message_list = []
        for key, value in self.mav.getMessageList().items():
            name = value[0]
            fields = self.mav.getMessageColumnNames(key)
            message_list.append({
                'id': key,
                'name': name,
                'fields': fields
            })
        return message_list

    @Slot(int, list, bool)
    def send_message(self, msg_id: int, data: list, is_float: bool):
        try:
            if is_float:
                data = list(struct.pack("<" + "f" * len(data), *data))
            self.mav.send(msg_id, data)
            print(f"메시지 {msg_id} 전송 성공: {data}")
        except Exception as e:
            print(f"메시지 전송 실패: {str(e)}")
