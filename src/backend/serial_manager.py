import time
import struct
import threading
import serial.tools.list_ports

from PySide6.QtCore import QObject, Signal, Slot
from pymavlink import mavutil

from .MiniLink.MiniLink import MiniLink

# PX4 커스텀 모드 상수
_PX4_MODE_GUIDED = 4
_PX4_MODE_AUTO_TAKEOFF = (2 << 24) | (4 << 16)
_PX4_MODE_LAND = (6 << 24) | (4 << 16)

# MAVLink 강제 ARM 매직 넘버
_MAV_FORCE_ARM = 21196


class SerialManager(QObject):
    """
    시리얼/UDP 연결 관리 클래스
    """

    messageUpdated = Signal(int, dict)   # 메시지 업데이트 시그널
    commandResult = Signal(str, bool, str)  # 명령어 이름, 성공 여부, 메시지
    connectionResult = Signal(bool, str)   # 연결 성공 여부, 메시지

    def __init__(self, parent=None):
        super().__init__(parent)
        # 시리얼 연결 정보
        self.is_px4 = False
        self.port = None
        self.baudrate = None

        # UDP 연결 정보
        self.udp_ip = None
        self.udp_port = None

        # 자작 FC용 MiniLink 객체
        self.minilink = MiniLink()

        # PX4용 MAVLink 객체
        self.mavlink = None

        # 데이터 읽기 스레드 관리
        self.data_reading_thread = None
        self.data_reading_thread_stop_flag = threading.Event()

        # Heartbeat 전송 스레드 관리 (PX4 전용)
        self.heartbeat_thread = None
        self.heartbeat_thread_stop_flag = threading.Event()

        # 메시지 통계 추적 (msg_id: {'count': int, 'start_time': float})
        self.message_stats = {}

    # ── 내부 헬퍼 ────────────────────────────────────────────────────────────

    def _require_mavlink(self, cmd_name: str) -> bool:
        """MAVLink 연결 여부 확인.
        연결이 없으면 commandResult 에러를 emit하고 False를 반환한다.
        """
        if not self.mavlink:
            msg = "MAVLink 연결이 없습니다."
            print(msg)
            self.commandResult.emit(cmd_name, False, msg)
            return False
        return True

    def _set_custom_mode(self, custom_mode: int):
        """PX4 커스텀 비행 모드 변경 (MAV_MODE_FLAG_CUSTOM_MODE_ENABLED 고정)."""
        self.mavlink.mav.set_mode_send(
            self.mavlink.target_system,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
            custom_mode,
        )

    def _send_command(self, command: int, *params, timeout: int = 3) -> tuple:
        """COMMAND_LONG 전송 후 ACK 대기.

        Returns:
            (success: bool, result_code: int | None)  — None이면 타임아웃
        """
        p = list(params) + [0] * (7 - len(params))
        self.mavlink.mav.command_long_send(
            self.mavlink.target_system,
            self.mavlink.target_component,
            command,
            0,       # confirmation
            *p[:7],
        )
        ack = self.mavlink.recv_match(type='COMMAND_ACK', blocking=True, timeout=timeout)
        if ack is None:
            return False, None
        return ack.result == 0, ack.result

    def _emit_ack_result(self, cmd_name: str, success: bool, result_code):
        """_send_command 결과를 commandResult 신호로 emit."""
        if result_code is None:
            self.commandResult.emit(cmd_name, False, "응답 시간 초과")
        else:
            msg = "성공" if success else f"실패 (코드: {result_code})"
            self.commandResult.emit(cmd_name, success, msg)

    # ── 포트 및 연결 ─────────────────────────────────────────────────────────

    @Slot(result=list)
    def getPortList(self):
        """QML에서 호출할 수 있는 슬롯 (포트 목록 전달)"""
        return [
            {'device': port.device, 'description': port.description}
            for port in serial.tools.list_ports.comports()
        ]

    @Slot(bool, str, int)
    def connectSerial(self, is_px4: bool, device: str, baudrate: int):
        """QML에서 연결 버튼을 누르면 호출될 슬롯 (비동기)"""
        if not device or not baudrate:
            msg = "오류: 포트 혹은 보율이 선택되지 않았습니다."
            print(msg)
            self.connectionResult.emit(False, msg)
            return
        if self.port is not None or self.baudrate is not None:
            msg = "이미 연결된 포트가 있습니다."
            print(msg)
            self.connectionResult.emit(False, msg)
            return

        def task():
            try:
                if is_px4:
                    self._connectSerialPX4(device, baudrate)
                else:
                    self._connectSerialFC(device, baudrate)
                print(f"{device}에 성공적으로 연결되었습니다.")

                self.is_px4 = is_px4
                self.port = device
                self.baudrate = baudrate

                self.data_reading_thread_stop_flag = threading.Event()
                if is_px4:
                    self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)

                    # PX4에 GCS가 활성 상태임을 알리기 위해 Heartbeat 전송 스레드도 시작
                    self.heartbeat_thread_stop_flag = threading.Event()
                    self.heartbeat_thread = threading.Thread(target=self._sendHeartbeat, daemon=True)
                    self.heartbeat_thread.start()
                else:
                    self.data_reading_thread = threading.Thread(target=self._getSensorDataFC, daemon=True)
                self.data_reading_thread.start()

                self.connectionResult.emit(True, f"{device} 연결 성공")
            except serial.SerialException as e:
                error_msg = f"시리얼 연결 실패: {e}"
                print(error_msg)
                if not is_px4:
                    self.minilink.disconnect()
                self.connectionResult.emit(False, error_msg)
            except Exception as e:
                error_msg = f"연결 실패: {e}"
                print(error_msg)
                if not is_px4:
                    self.minilink.disconnect()
                self.connectionResult.emit(False, error_msg)

        threading.Thread(target=task, daemon=True).start()

    @Slot(str, int)
    def connectUDP(self, ip: str, port: int):
        """PX4 UDP 연결 설정 (비동기)"""
        def task():
            try:
                self._connectUDPPX4(ip, port)
                print(f"PX4 UDP {ip}:{port}에 성공적으로 연결되었습니다.")

                self.is_px4 = True
                self.udp_ip = ip
                self.udp_port = port

                self.data_reading_thread_stop_flag = threading.Event()
                self.data_reading_thread = threading.Thread(target=self._getSensorDataPX4, daemon=True)
                self.data_reading_thread.start()

                self.heartbeat_thread_stop_flag = threading.Event()
                self.heartbeat_thread = threading.Thread(target=self._sendHeartbeat, daemon=True)
                self.heartbeat_thread.start()

                self.connectionResult.emit(True, f"UDP {ip}:{port} 연결 성공")
            except Exception as e:
                error_msg = f"UDP 연결 실패: {e}"
                print(error_msg)
                self.is_px4 = False
                self.udp_ip = None
                self.udp_port = None
                self.connectionResult.emit(False, error_msg)

        threading.Thread(target=task, daemon=True).start()

    def _connectSerialFC(self, port: str, baudrate: int):
        """센서와 연결을 시도합니다."""
        self.minilink.connect(port, baudrate)

        self.minilink.chooseMessage(26)
        start_time = time.time()
        while True:
            data: list = self.minilink.read(enPrint=True, enLog=False)
            if data:
                print("연결 성공")
                break
            if time.time() - start_time > 2:
                print("연결 실패")
                raise serial.SerialException("연결 실패: 데이터 수신 대기 시간 초과")

    def _connectSerialPX4(self, port: str, baudrate: int):
        """PX4와 MAVLink로 연결을 시도합니다."""
        self.mavlink = mavutil.mavlink_connection(port, baud=baudrate, source_system=255)
        heartbeat = self.mavlink.wait_heartbeat(timeout=2)
        if not heartbeat:
            raise serial.SerialException("PX4 연결 실패: HEARTBEAT 수신 대기 시간 초과")
        print("PX4 HEARTBEAT 수신 성공")

    def _connectUDPPX4(self, ip: str, port: int):
        """PX4와 MAVLink로 UDP 연결을 시도합니다."""
        self.mavlink = mavutil.mavlink_connection(f'udpin:{ip}:{port}', source_system=255)
        heartbeat = self.mavlink.wait_heartbeat(timeout=2)
        if not heartbeat:
            raise ConnectionError("PX4 UDP 연결 실패: HEARTBEAT 수신 대기 시간 초과")
        print("PX4 UDP HEARTBEAT 수신 성공")

    # ── 데이터 수신 루프 ──────────────────────────────────────────────────────

    def _getSensorDataFC(self):
        """시리얼로 연결한 FC 센서 데이터를 지속적으로 읽는 메인 루프"""
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
                    msg = dict(zip(message_frame[msg_id], data))
                    self._update_message_stats(msg_id)
                    self.messageUpdated.emit(msg_id, msg)

                    current_message_idx = (current_message_idx + 1) % len(message_id_list)
                    msg_id = message_id_list[current_message_idx]
                    self.minilink.chooseMessage(msg_id)
        except Exception as e:
            print(f"[Data Reading Thread] 연결 끊김 감지: {e}")
            self.port = None
            self.baudrate = None

    def _getSensorDataPX4(self):
        """PX4와 MAVLink로 연결한 센서 데이터를 지속적으로 읽는 메인 루프"""
        try:
            while not self.data_reading_thread_stop_flag.is_set():
                msg = self.mavlink.recv_match(blocking=True, timeout=1)
                if msg:
                    msg_id = msg.get_msgId()
                    msg_dict = msg.to_dict()
                    self._update_message_stats(msg_id)
                    self.messageUpdated.emit(msg_id, msg_dict)
        except Exception as e:
            print(f"[Data Reading Thread] 연결 끊김 감지: {e}")
            self.port = None
            self.baudrate = None

    def _sendHeartbeat(self):
        """PX4에 1초마다 Heartbeat 메시지를 전송하는 스레드"""
        try:
            while not self.heartbeat_thread_stop_flag.is_set():
                if self.mavlink:
                    self.mavlink.mav.heartbeat_send(
                        mavutil.mavlink.MAV_TYPE_GCS,
                        mavutil.mavlink.MAV_AUTOPILOT_INVALID,
                        0, 0,
                        mavutil.mavlink.MAV_STATE_ACTIVE,
                    )
                self.heartbeat_thread_stop_flag.wait(1.0)
        except Exception as e:
            print(f"[Heartbeat Thread] 오류 발생: {e}")

    # ── 통계 / 조회 슬롯 ─────────────────────────────────────────────────────

    def _update_message_stats(self, msg_id: int):
        """메시지 통계 업데이트 (count, start_time)"""
        if msg_id not in self.message_stats:
            self.message_stats[msg_id] = {'count': 0, 'start_time': time.time()}
        self.message_stats[msg_id]['count'] += 1

    @Slot(int, result=float)
    def getMessageHz(self, msg_id: int):
        """특정 메시지의 Hz(주파수)를 계산하여 반환"""
        if msg_id not in self.message_stats:
            return 0.0
        stats = self.message_stats[msg_id]
        elapsed = time.time() - stats['start_time']
        return stats['count'] / elapsed if elapsed > 0 else 0.0

    @Slot(result=dict)
    def getCurrentConnection(self):
        """현재 연결된 시리얼/UDP 연결 정보를 반환합니다."""
        return {
            'is_px4':    self.is_px4,
            'is_serial': self.port is not None,
            'port':      self.port,
            'baudrate':  self.baudrate,
            'udp_ip':    self.udp_ip,
            'udp_port':  self.udp_port,
        }

    @Slot(result=list)
    def getMessageList(self):
        """현재 연결된 센서의 메시지 목록을 반환합니다."""
        message_list = []

        if self.is_px4:
            if self.mavlink:
                for msg_name, msg_def in self.mavlink.messages.items():
                    if '[' in msg_name:
                        continue
                    if not (hasattr(msg_def, 'get_msgId') and hasattr(msg_def, 'fieldnames') and hasattr(msg_def, 'get_type')):
                        continue
                    # pymavlink은 동일 메시지를 여러 키('GPS_RAW_INT', 'HOME' 등)로 저장하는 경우가 있음
                    # dict 키(msg_name)와 메시지 자신의 타입명이 다른 synthetic alias는 건너뜀
                    if msg_name != msg_def.get_type():
                        continue
                    msg_id = msg_def.get_msgId()
                    message_list.append({
                        'id':     msg_id,
                        'name':   msg_name,
                        'fields': msg_def.fieldnames,
                        'rate':   self.getMessageHz(msg_id),
                    })
        else:
            if self.minilink:
                for key, value in self.minilink.getMessageList().items():
                    message_list.append({
                        'id':     key,
                        'name':   value[0],
                        'fields': self.minilink.getMessageColumnNames(key),
                        'rate':   self.getMessageHz(key),
                    })

        message_list.sort(key=lambda x: x['id'])
        return message_list

    # ── 연결 해제 슬롯 ───────────────────────────────────────────────────────

    @Slot(result=bool)
    def disconnectSerial(self):
        """시리얼 연결 해제 슬롯"""
        self.data_reading_thread_stop_flag.set()
        if self.is_px4 and self.heartbeat_thread is not None:
            self.heartbeat_thread_stop_flag.set()

        if self.data_reading_thread is not None:
            self.data_reading_thread.join()
        if self.is_px4 and self.heartbeat_thread is not None:
            self.heartbeat_thread.join()

        if self.is_px4:
            if self.mavlink:
                self.mavlink.close()
        else:
            if not self.minilink.disconnect():
                print("시리얼 연결 해제에 실패했습니다.")
                return False

        self.mavlink = None
        self.port = None
        self.baudrate = None
        self.heartbeat_thread = None
        self.message_stats = {}
        print("시리얼 연결이 해제되었습니다.")
        return True

    @Slot(result=bool)
    def disconnectUDP(self):
        """UDP 연결 해제 슬롯"""
        self.data_reading_thread_stop_flag.set()
        if self.heartbeat_thread is not None:
            self.heartbeat_thread_stop_flag.set()

        if self.data_reading_thread is not None:
            self.data_reading_thread.join()
        if self.heartbeat_thread is not None:
            self.heartbeat_thread.join()

        if self.mavlink:
            self.mavlink.close()
        self.mavlink = None
        self.udp_ip = None
        self.udp_port = None
        self.heartbeat_thread = None
        self.message_stats = {}
        print("PX4 UDP 연결이 해제되었습니다.")
        return True

    # ── 데이터 전송 슬롯 ─────────────────────────────────────────────────────

    @Slot(int, list, bool)
    def send_message(self, msg_id: int, data: list, is_float: bool):
        try:
            if is_float:
                data = list(struct.pack("<" + "f" * len(data), *data))
            self.minilink.send(msg_id, data)
            print(f"메시지 {msg_id} 전송 성공: {data}")
        except Exception as e:
            print(f"메시지 전송 실패: {e}")

    # ── 비행 명령 슬롯 ───────────────────────────────────────────────────────

    @Slot(bool)
    def sendArmCommand(self, arm: bool):
        """드론 ARM/DISARM 명령 전송 (비동기)"""
        cmd_name = "ARM" if arm else "DISARM"
        if not self._require_mavlink(cmd_name):
            return

        def task():
            try:
                if arm:
                    self._set_custom_mode(_PX4_MODE_GUIDED)
                    print("모드 변경 명령 전송 (GUIDED)")
                    time.sleep(0.1)

                success, result = self._send_command(
                    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
                    1 if arm else 0,
                    _MAV_FORCE_ARM if arm else 0,
                )
                print(f"{cmd_name} 명령 응답: result={result} (0=성공, 1=임시거부, 2=거부, 3=지원안함, 4=실패, 5=진행중)")
                self._emit_ack_result(cmd_name, success, result)
            except Exception as e:
                print(f"{cmd_name} 명령 전송 실패: {e}")
                self.commandResult.emit(cmd_name, False, str(e))

        threading.Thread(target=task, daemon=True).start()

    @Slot(float)
    def sendTakeoffCommand(self, altitude: float):
        """자동 ARM 후 이륙 모드로 변경 (비동기)
        altitude 파라미터는 API 호환성을 위해 수신하나, PX4 모드 전환에는 사용되지 않음.
        """
        if not self._require_mavlink("TAKEOFF"):
            return

        def task():
            # 1. 자동 ARM
            print("이륙 전 자동 ARM 시도 중...")
            try:
                self._set_custom_mode(_PX4_MODE_GUIDED)
                time.sleep(0.1)
                success, result = self._send_command(
                    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 1, _MAV_FORCE_ARM,
                )
                if not success:
                    msg = "자동 ARM 실패로 이륙 중단"
                    print(msg)
                    self.commandResult.emit("TAKEOFF", False, msg)
                    return
            except Exception as e:
                msg = f"자동 ARM 중 오류: {e}"
                print(msg)
                self.commandResult.emit("TAKEOFF", False, msg)
                return

            print("ARM 성공, 1초 대기 후 이륙 모드로 전환합니다.")
            time.sleep(1.0)

            # 2. PX4 AUTO.TAKEOFF 모드 전환
            try:
                self._set_custom_mode(_PX4_MODE_AUTO_TAKEOFF)
                print("TAKEOFF 모드 변경 명령 전송")
                time.sleep(0.5)
                self.commandResult.emit("TAKEOFF", True, "Takeoff 모드 변경 성공")
            except Exception as e:
                msg = f"TAKEOFF 모드 변경 실패: {e}"
                print(msg)
                self.commandResult.emit("TAKEOFF", False, msg)

        threading.Thread(target=task, daemon=True).start()

    @Slot()
    def sendLandCommand(self):
        """착륙 모드로 변경 (비동기)"""
        if not self._require_mavlink("LAND"):
            return

        def task():
            try:
                self._set_custom_mode(_PX4_MODE_LAND)
                print("LAND 모드 변경 명령 전송")
                time.sleep(0.5)
                self.commandResult.emit("LAND", True, "Land 모드 변경 성공")
            except Exception as e:
                msg = f"LAND 모드 변경 실패: {e}"
                print(msg)
                self.commandResult.emit("LAND", False, msg)

        threading.Thread(target=task, daemon=True).start()

    @Slot()
    def sendReturnCommand(self):
        """RTL 명령 전송 (비동기)"""
        if not self._require_mavlink("RTL"):
            return

        def task():
            try:
                success, result = self._send_command(mavutil.mavlink.MAV_CMD_NAV_RETURN_TO_LAUNCH)
                print(f"RTL 명령 응답: result={result}")
                self._emit_ack_result("RTL", success, result)
            except Exception as e:
                msg = f"RTL 명령 전송 실패: {e}"
                print(msg)
                self.commandResult.emit("RTL", False, msg)

        threading.Thread(target=task, daemon=True).start()

    @Slot(str)
    def setFlightMode(self, mode: str):
        """비행 모드 변경 (비동기)"""
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
        cmd_name = f"MODE_{mode}"

        if mode not in mode_map:
            msg = f"알 수 없는 모드: {mode}"
            print(msg)
            self.commandResult.emit(cmd_name, False, msg)
            return

        if not self._require_mavlink(cmd_name):
            return

        def task():
            try:
                self._set_custom_mode(mode_map[mode])
                print(f"{mode} 모드 변경 명령 전송")
                time.sleep(0.5)
                self.commandResult.emit(cmd_name, True, f"{mode} 모드로 변경 성공")
            except Exception as e:
                msg = f"{mode} 모드 변경 실패: {e}"
                print(msg)
                self.commandResult.emit(cmd_name, False, msg)

        threading.Thread(target=task, daemon=True).start()
