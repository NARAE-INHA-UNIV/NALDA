import time
import struct
import threading
import serial.tools.list_ports

from PySide6.QtCore import QObject, Signal, Slot
from pymavlink import mavutil

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

        # PX4용 MAVLink 객체
        self.mavlink = None

        # 데이터 읽기 전용 스레드 관리
        self.data_reading_thread = None
        self.data_reading_thread_stop_flag = threading.Event()

# Heartbeat 전송 스레드 관리 (PX4 전용)
        self.heartbeat_thread = None
        self.heartbeat_thread_stop_flag = threading.Event()

        # 메시지 통계 추적 (msg_id: {'count': int, 'start_time': float})
        self.message_stats = {}

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

            # 데이터 읽기 스레드 시작
            self.data_reading_thread_stop_flag = threading.Event()
            if is_px4:
                self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)
                # Heartbeat 전송 스레드 시작
                self.heartbeat_thread_stop_flag = threading.Event()
                self.heartbeat_thread = threading.Thread(target=self._sendHeartbeat, daemon=True)
                self.heartbeat_thread.start()
            else:
                self.data_reading_thread = threading.Thread(target=self._getSensorDataFC, daemon=True)
            self.data_reading_thread.start()

            return True
        except serial.SerialException as e:
            error_msg = f"시리얼 연결 실패: {str(e)}"
            print(error_msg)
            if not is_px4:
                self.minilink.disconnect()
            return False
        except Exception as e:
            error_msg = f"연결 실패: {str(e)}"
            print(error_msg)
            if not is_px4:
                self.minilink.disconnect()
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
            self.is_px4 = True
            self.udp_ip = ip
            self.udp_port = port

            # 데이터 읽기 스레드 시작
            self.data_reading_thread_stop_flag = threading.Event()
            self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)
            self.data_reading_thread.start()

            # Heartbeat 전송 스레드 시작
            self.heartbeat_thread_stop_flag = threading.Event()
            self.heartbeat_thread = threading.Thread(target=self._sendHeartbeat, daemon=True)
            self.heartbeat_thread.start()

            return True
        except Exception as e:
            error_msg = f"UDP 연결 실패: {str(e)}"
            print(error_msg)
            self.is_px4 = False
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

        self.mavlink = mavutil.mavlink_connection(port, baud=baudrate, source_system=255)

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

        self.mavlink = mavutil.mavlink_connection(f'udpin:{ip}:{port}', source_system=255)

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
            message_list = self.getMessageList()
            message_id_list = [msg['id'] for msg in message_list]
            message_frame = {msg['id']: msg['fields'] for msg in message_list}

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

                    # 메시지 통계 업데이트
                    self._update_message_stats(msg_id)

                    self.messageUpdated.emit(msg_id, msg)

                    # 다음 메시지 선택
                    current_message_idx = (current_message_idx + 1) % len(message_id_list)
                    msg_id = message_id_list[current_message_idx]
                    self.minilink.chooseMessage(msg_id)
        except Exception as e:
            print("[Data Reading Thread] 연결 끊김 감지!")
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
                    msg_dict = msg.to_dict()

                    # 메시지 통계 업데이트
                    self._update_message_stats(msg_id)

                    self.messageUpdated.emit(msg_id, msg_dict)
        except Exception as e:
            print("[Data Reading Thread] 연결 끊김 감지!")
            self.port = None
            self.baudrate = None
            return

    def _sendHeartbeat(self):
        """
        PX4에 1초마다 Heartbeat 메시지를 전송하는 스레드
        지상관제 시스템으로 인식되도록 함
        """
        try:
            while not self.heartbeat_thread_stop_flag.is_set():
                if self.mavlink:
                    # MAV_TYPE_GCS (지상관제), MAV_AUTOPILOT_INVALID, base_mode=0, custom_mode=0, system_status=MAV_STATE_ACTIVE
                    self.mavlink.mav.heartbeat_send(
                        mavutil.mavlink.MAV_TYPE_GCS,  # type: GCS (Ground Control Station)
                        mavutil.mavlink.MAV_AUTOPILOT_INVALID,  # autopilot
                        0,  # base_mode
                        0,  # custom_mode
                        mavutil.mavlink.MAV_STATE_ACTIVE  # system_status
                    )
                # 1초 대기 (stop_flag 체크하면서)
                self.heartbeat_thread_stop_flag.wait(1.0)
        except Exception as e:
            print(f"[Heartbeat Thread] 오류 발생: {str(e)}")
            return

    def _update_message_stats(self, msg_id: int):
        """
        메시지 통계 업데이트 (count, start_time)
        """
        current_time = time.time()

        if msg_id not in self.message_stats:
            self.message_stats[msg_id] = {
                'count': 0,
                'start_time': current_time
            }

        self.message_stats[msg_id]['count'] += 1

    @Slot(int, result=float)
    def getMessageHz(self, msg_id: int):
        """
        특정 메시지의 Hz(주파수)를 계산하여 반환
        """
        if msg_id not in self.message_stats:
            return 0.0

        stats = self.message_stats[msg_id]
        elapsed_time = time.time() - stats['start_time']

        if elapsed_time <= 0:
            return 0.0

        hz = stats['count'] / elapsed_time
        return hz

    @Slot(result=bool)
    def disconnectSerial(self):
        """
        시리얼 연결 해제 슬롯
        """

        # 스레드 종료를 위한 이벤트 설정
        self.data_reading_thread_stop_flag.set()
        if self.is_px4 and self.heartbeat_thread is not None:
            self.heartbeat_thread_stop_flag.set()

        # 스레드 종료 대기
        if self.data_reading_thread is not None:
            self.data_reading_thread.join()
        if self.is_px4 and self.heartbeat_thread is not None:
            self.heartbeat_thread.join()

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
        self.heartbeat_thread = None
        self.message_stats = {}  # 통계 초기화
        print("시리얼 연결이 해제되었습니다.")
        return True

    @Slot(result=bool)
    def disconnectUDP(self):
        """
        UDP 연결 해제 슬롯
        """

        # 스레드 종료를 위한 이벤트 설정
        self.data_reading_thread_stop_flag.set()
        if self.heartbeat_thread is not None:
            self.heartbeat_thread_stop_flag.set()

        # 스레드 종료 대기
        if self.data_reading_thread is not None:
            self.data_reading_thread.join()
        if self.heartbeat_thread is not None:
            self.heartbeat_thread.join()

        # UDP 연결 해제
        self.mavlink.close()
        self.mavlink = None
        self.udp_ip = None
        self.udp_port = None
        self.heartbeat_thread = None
        self.message_stats = {}  # 통계 초기화
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
        현재 연결된 센서의 메시지 목록을 반환합니다.
        """

        message_list = []

        if self.is_px4:
            # PX4 MAVLink 메시지 목록
            if self.mavlink:
                mavlink_messages = self.mavlink.messages
                for msg_name, msg_def in mavlink_messages.items():
                    if '[' in msg_name:
                        continue
                    if hasattr(msg_def, 'get_msgId') and hasattr(msg_def, 'fieldnames'):
                        if msg_def.get_msgId() == 0:
                            continue
                        message_list.append({
                            'id': msg_def.get_msgId(),
                            'name': msg_name,
                            'fields': msg_def.fieldnames,
                            'rate': self.getMessageHz(msg_def.get_msgId())
                        })
        else:
            # 자작 FC 메시지 목록
            if self.minilink:
                for key, value in self.minilink.getMessageList().items():
                    message_list.append({
                        'id': key,
                        'name': value[0],
                        'fields': self.minilink.getMessageColumnNames(key),
                        'rate': self.getMessageHz(key)
                    })

        message_list.sort(key=lambda x: x['id'])
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

    @Slot(bool)
    def sendArmCommand(self, arm: bool):
        """
        드론 ARM/DISARM 명령 전송
        """
        if not self.mavlink:
            print("MAVLink 연결이 없습니다.")
            return

        try:
            # 먼저 Guided 모드로 변경 (arm 시에만)
            if arm:
                self.mavlink.mav.set_mode_send(
                    self.mavlink.target_system,
                    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                    4  # PX4: 4 = AUTO.TAKEOFF, GUIDED
                )
                print(f"모드 변경 명령 전송 (GUIDED)")
                time.sleep(0.1)  # 모드 변경 대기

            self.mavlink.mav.command_long_send(
                self.mavlink.target_system,
                self.mavlink.target_component,
                mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                0,  # confirmation
                1 if arm else 0,  # param1: 1=arm, 0=disarm
                21196 if arm else 0,  # param2: 강제 arm (21196 = force arm)
                0, 0, 0, 0, 0  # param3-7
            )
            print(f"{'ARM' if arm else 'DISARM'} 명령 전송 (target_system={self.mavlink.target_system}, target_component={self.mavlink.target_component})")

            # 명령 응답 대기
            ack = self.mavlink.recv_match(type='COMMAND_ACK', blocking=True, timeout=3)
            if ack:
                print(f"ARM 명령 응답: result={ack.result} (0=성공, 1=임시거부, 2=거부, 3=지원안함, 4=실패, 5=진행중)")
        except Exception as e:
            print(f"ARM 명령 전송 실패: {str(e)}")

    @Slot(float)
    def sendTakeoffCommand(self, altitude: float):
        """
        이륙 모드로 변경 (AUTO.TAKEOFF)
        """
        if not self.mavlink:
            print("MAVLink 연결이 없습니다.")
            return

        # PX4 AUTO.TAKEOFF 모드로 전환
        # Custom mode = (sub_mode << 24) | (main_mode << 16)
        # AUTO(4).TAKEOFF(2) = (2 << 24) | (4 << 16) = 0x02040000
        custom_mode = (2 << 24) | (4 << 16)  # 33685504

        try:
            # AUTO.TAKEOFF 모드로 변경 (PX4 custom_mode = 10)
            self.mavlink.mav.set_mode_send(
                self.mavlink.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                custom_mode
            )
            print(f"TAKEOFF 모드 변경 명령 전송 (target_system={self.mavlink.target_system})")

            # 모드 변경 응답 대기
            time.sleep(0.5)
        except Exception as e:
            print(f"TAKEOFF 모드 변경 실패: {str(e)}")

    @Slot()
    def sendLandCommand(self):
        """
        착륙 모드로 변경 (AUTO.LAND)
        """
        if not self.mavlink:
            print("MAVLink 연결이 없습니다.")
            return

        # PX4 AUTO.LAND 모드로 전환
        # Custom mode = (sub_mode << 24) | (main_mode << 16)
        # AUTO(4).LAND(6) = (6 << 24) | (4 << 16) = 0x06040000
        custom_mode = (6 << 24) | (4 << 16)  # 100663296

        try:
            # AUTO.LAND 모드로 변경 (PX4 custom_mode = 11)
            self.mavlink.mav.set_mode_send(
                self.mavlink.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                custom_mode
            )
            print(f"LAND 모드 변경 명령 전송 (target_system={self.mavlink.target_system})")

            # 모드 변경 응답 대기
            time.sleep(0.5)
        except Exception as e:
            print(f"LAND 모드 변경 실패: {str(e)}")

    @Slot()
    def sendReturnCommand(self):
        """
        RTL (Return to Launch) 명령 전송
        """
        if not self.mavlink:
            print("MAVLink 연결이 없습니다.")
            return

        try:
            self.mavlink.mav.command_long_send(
                self.mavlink.target_system,
                self.mavlink.target_component,
                mavutil.mavlink.MAV_CMD_NAV_RETURN_TO_LAUNCH,
                0,  # confirmation
                0, 0, 0, 0, 0, 0, 0
            )
            print(
                f"RETURN TO LAUNCH 명령 전송 (target_system={self.mavlink.target_system}, target_component={self.mavlink.target_component})")

            # 명령 응답 대기
            ack = self.mavlink.recv_match(type='COMMAND_ACK', blocking=True, timeout=3)
            if ack:
                print(f"RTL 명령 응답: result={ack.result} (0=성공, 1=임시거부, 2=거부, 3=지원안함, 4=실패, 5=진행중)")
        except Exception as e:
            print(f"RTL 명령 전송 실패: {str(e)}")

    @Slot(str)
    def setFlightMode(self, mode: str):
        """
        비행 모드 변경
        """
        if not self.mavlink:
            print("MAVLink 연결이 없습니다.")
            return

        # PX4 custom mode 매핑
        mode_map = {
            'MANUAL': 1,
            'STABILIZED': 2,
            'ACRO': 3,
            'RATTITUDE': 4,
            'ALTCTL': 5,
            'POSCTL': 6,
            'LOITER': 7,
            'MISSION': 8,
            'RTL': 9,
            'TAKEOFF': 10,
            'LAND': 11,
            'RTGS': 12,
            'FOLLOWME': 13,
            'OFFBOARD': 14,
        }

        if mode not in mode_map:
            print(f"알 수 없는 모드: {mode}")
            return

        try:
            custom_mode = mode_map[mode]
            self.mavlink.mav.set_mode_send(
                self.mavlink.target_system,
                mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
                custom_mode
            )
            print(f"{mode} 모드 변경 명령 전송 (custom_mode={custom_mode})")
            time.sleep(0.5)
        except Exception as e:
            print(f"{mode} 모드 변경 실패: {str(e)}")
