import time
import struct
import threading
import serial.tools.list_ports

from PySide6.QtCore import QObject, Signal, Slot
from pymavlink import mavutil
from types import SimpleNamespace

from .MiniLink.MiniLink import MiniLink


class SerialManager(QObject):
    """
    시리얼/UDP 연결 관리 클래스
    """

    messageUpdated = Signal(int, dict)  # 메시지 업데이트 시그널

    def __init__(self, parent=None):
        super().__init__(parent)
        # 시리얼 연결 정보
        self.is_px4 = False   # PX4, 자작 FC 구분
        self.port = None      # 현재 연결된 포트
        self.baudrate = None  # 현재 연결된 보드레이트

        # UDP 연결 정보
        self.udp_ip = None
        self.udp_port = None

        # 자작 FC용 MiniLink 객체 및 데이터 저장
        self.minilink = MiniLink()
        self.message_list = []

        # PX4용 MAVLink 객체
        self.mavlink = None

        # 데이터 읽기 전용 스레드 관리
        self.data_reading_thread = None
        self.data_reading_thread_stop_flag = threading.Event()

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

    @Slot(bool, str, int, result=bool)
    def connectSerial(self, is_px4: bool, device: str, baudrate: int):
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
            if is_px4:
                self._connectSerialPX4(device, baudrate)
            else:
                self._connectSerialFC(device, baudrate)
            print(f"{device}에 성공적으로 연결되었습니다.")

            # 연결된 포트와 보드레이트 저장
            self.is_px4 = is_px4
            self.port = device
            self.baudrate = baudrate

            # 메시지 목록 가져오기
            self.message_list = self.getMessageList()

            # 데이터 읽기 스레드 시작
            self.data_reading_thread_stop_flag = threading.Event()
            if is_px4:
                self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)
            else:
                self.data_reading_thread = threading.Thread(target=self._getSensorDataFC, daemon=True)
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

    @Slot(str, int, result=bool)
    def connectUDP(self, ip: str, port: int):
        """
        PX4 UDP 연결 설정
        """

        try:
            self._connectUDPPX4(ip, port)
            print(f"PX4 UDP {ip}:{port}에 성공적으로 연결되었습니다.")

            # 연결된 IP와 포트 저장
            self.udp_ip = ip
            self.udp_port = port

            # 데이터 읽기 스레드 시작
            self.data_reading_thread_stop_flag = threading.Event()
            self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)
            self.data_reading_thread.start()
            return True
        except Exception as e:
            error_msg = f"UDP 연결 실패: {str(e)}"
            print(error_msg)
            self.udp_ip = None
            self.udp_port = None

    def _connectSerialFC(self, port: str, baudrate: int):
        """
        센서와 연결을 시도합니다.
        예외가 발생하면 상위 클래스에서 처리하도록 합니다.
        """

        self.minilink.connect(port, baudrate)

        # 연결 확인 코드
        # self.minilink.connect() 내부의 serial.Serial()은 시리얼 포트를 여는 코드일 뿐, 실제로 연결됐는지를 보장하지 않음
        # 따라서, 연결 후 2초 동안 데이터 수신이 없으면 연결 실패로 간주
        self.minilink.chooseMessage(26)
        start_time = time.time()
        while True:
            data: list = self.minilink.read(enPrint=True, enLog=False)
            if data:
                print("연결 성공")
                break
            if time.time() - start_time > 2:  # 2초 동안 데이터가 없으면 연결 실패로 간주
                print("연결 실패")
                raise serial.SerialException("연결 실패: 데이터 수신 대기 시간 초과")

    def _connectSerialPX4(self, port: str, baudrate: int):
        """
        PX4와 MAVLink로 연결을 시도합니다.
        예외가 발생하면 상위 클래스에서 처리하도록 합니다.
        """

        self.mavlink = mavutil.mavlink_connection(port, baud=baudrate)

        # 연결 확인 코드
        heartbeat = self.mavlink.wait_heartbeat(timeout=2)
        if not heartbeat:
            raise serial.SerialException("PX4 연결 실패: HEARTBEAT 수신 대기 시간 초과")
        print("PX4 HEARTBEAT 수신 성공")

    def _connectUDPPX4(self, ip: str, port: int):
        """
        PX4와 MAVLink로 UDP 연결을 시도합니다.
        예외가 발생하면 상위 클래스에서 처리하도록 합니다.
        """

        self.mavlink = mavutil.mavlink_connection(f'udpin:{ip}:{port}')

        # 연결 확인 코드
        heartbeat = self.mavlink.wait_heartbeat(timeout=2)
        if not heartbeat:
            raise ConnectionError("PX4 UDP 연결 실패: HEARTBEAT 수신 대기 시간 초과")
        print("PX4 UDP HEARTBEAT 수신 성공")

    def _getSensorDataFC(self):
        """
        시리얼로 연결한 FC 센서 데이터를 지속적으로 읽는 메인 루프
        """

        try:
            message_id_list = [msg['id'] for msg in self.message_list]
            message_frame = {msg['id']: msg['fields'] for msg in self.message_list}

            current_message_idx = 0
            msg_id = message_id_list[current_message_idx]
            self.minilink.chooseMessage(msg_id)
            while not self.data_reading_thread_stop_flag.is_set():
                data: list = self.minilink.read(enPrint=False, enLog=False)
                if data:
                    # 데이터 맵핑
                    msg = {}
                    for key, value in zip(message_frame[msg_id], data):
                        msg[key] = value
                    msg = SimpleNamespace(**msg)  # dict -> 객체 변환, mavlink 스타일 맞춤

                    self.messageUpdated.emit(msg_id, msg)

                    # 다음 메시지 선택
                    current_message_idx = (current_message_idx + 1) % len(message_id_list)
                    msg_id = message_id_list[current_message_idx]
                    self.minilink.chooseMessage(msg_id)
        except Exception as e:
            print("[Monitor] 연결 끊김 감지!")
            self.port = None
            self.baudrate = None
            return

    def _getSensorDataPX4(self):
        """
        PX4와 MAVLink로 연결한 센서 데이터를 지속적으로 읽는 메인 루프
        """

        try:
            while not self.data_reading_thread_stop_flag.is_set():
                msg = self.mavlink.recv_match(blocking=True, timeout=1)
                if msg:
                    msg_id = msg.get_msgId()
                    self.messageUpdated.emit(msg_id, msg)
        except Exception as e:
            print("[Monitor] 연결 끊김 감지!")
            self.port = None
            self.baudrate = None
            return

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
        if self.is_px4:
            self.mavlink.close()
        else:
            res = self.minilink.disconnect()
            if not res:
                print("시리얼 연결 해제에 실패했습니다.")
                return False

        self.mavlink = None
        self.port = None
        self.baudrate = None
        print("PX4 시리얼 연결이 해제되었습니다.")
        return True

    @Slot(result=bool)
    def disconnectUDP(self):
        """
        UDP 연결 해제 슬롯
        """

        # 스레드 종료를 위한 이벤트 설정
        self.data_reading_thread_stop_flag.set()

        # 스레드 종료 대기
        self.data_reading_thread.join()

        # UDP 연결 해제
        self.mavlink.close()
        self.mavlink = None
        self.udp_ip = None
        self.udp_port = None
        print("PX4 UDP 연결이 해제되었습니다.")
        return True

    @Slot(result=dict)
    def getCurrentConnection(self):
        """
        현재 연결된 시리얼/UDP 연결 정보를 반환합니다.
        """

        return {
            'is_px4': self.is_px4,
            'is_serial': self.port is not None,
            'port': self.port,
            'baudrate': self.baudrate,
            'udp_ip': self.udp_ip,
            'udp_port': self.udp_port
        }

    @Slot(result=list)
    def getMessageList(self):
        """
        자작 FC용 MiniLink에서
        현재 연결된 센서의 메시지 목록을 반환합니다.
        """

        message_list = []
        for key, value in self.minilink.getMessageList().items():
            name = value[0]
            fields = self.minilink.getMessageColumnNames(key)
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
            self.minilink.send(msg_id, data)
            print(f"메시지 {msg_id} 전송 성공: {data}")
        except Exception as e:
            print(f"메시지 전송 실패: {str(e)}")
