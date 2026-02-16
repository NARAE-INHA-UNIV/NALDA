import time

from PySide6.QtCore import QObject, Signal, Slot
from .MiniLink.lib.xmlHandler import XmlHandler

from windows.pid_tunner_window import PIDTunnerWindow


class AttitudeOverviewManager(QObject):
    graphDataUpdated = Signal(dict)  # 메시지 업데이트 시그널
    newPidGains = Signal(int, list, bool)     # 새로운 PID 게인 시그널

    def __init__(self):
        super().__init__()
        self.target_message_ids = [
            30,  # ATTITUDE
            36,  # SERVO_OUTPUT_RAW
        ]

        self.message_data_frame = {
            'time_usec': 0,
            'roll': None,
            'pitch': None,
            'yaw': None,
            'rollspeed': None,
            'pitchspeed': None,
            'yawspeed': None,
            'servo1_raw': None,
            'servo2_raw': None,
            'servo3_raw': None,
            'servo4_raw': None,
        }
        self.message_fields = [
            {'type': 'uint32_t', 'name': 'time_usec',  'plot': True, 'units': 'us'},
            {'type': 'float', 'name': 'roll',  'plot': True, 'units': 'degree'},
            {'type': 'float', 'name': 'pitch',  'plot': True, 'units': 'degree'},
            {'type': 'float', 'name': 'yaw',  'plot': True, 'units': 'degree'},
            {'type': 'float', 'name': 'rollspeed',  'plot': True, 'units': 'degree/s'},
            {'type': 'float', 'name': 'pitchspeed',  'plot': True, 'units': 'degree/s'},
            {'type': 'float', 'name': 'yawspeed',  'plot': True, 'units': 'degree/s'},
            {'type': 'uint16_t', 'name': 'servo1_raw',  'plot': True, 'units': ''},
            {'type': 'uint16_t', 'name': 'servo2_raw',  'plot': True, 'units': ''},
            {'type': 'uint16_t', 'name': 'servo3_raw',  'plot': True, 'units': ''},
            {'type': 'uint16_t', 'name': 'servo4_raw',  'plot': True, 'units': ''},
        ]

        self.xmlHandler = XmlHandler()
        self.xmlHandler.loadMessageListFromXML({})

        # # Location History 창을 관리하기 위한 변수
        self.pid_tunner_window = PIDTunnerWindow()
        self.pid_tunner_window.hide()
        # self.pid_tunner_window.show()

    @Slot(int, dict)
    def get_data(self, message_id: int, data: dict):
        """
        SerialManager에 메시지가 전달되면 호출되는 슬롯
        """
        if message_id in self.target_message_ids:
            result = self.message_data_frame.copy()  # 기존 프레임을 복사하여 초기화
            if message_id == 30:  # ATTITUDE
                result['time_usec'] = data.get('time_boot_ms', 0) * 1000  # ms를 us로 변환
                result['roll'] = data.get('roll', None) * 57.2958  # 라디안을 도로 변환
                result['pitch'] = data.get('pitch', None) * 57.2958
                result['yaw'] = data.get('yaw', None) * 57.2958
                result['rollspeed'] = data.get('rollspeed', None) * 57.2958
                result['pitchspeed'] = data.get('pitchspeed', None) * 57.2958
                result['yawspeed'] = data.get('yawspeed', None) * 57.2958
            elif message_id == 36:  # SERVO_OUTPUT_RAW
                result['time_usec'] = data.get('time_usec', 0)
                result['servo1_raw'] = data.get('servo1_raw', None)
                result['servo2_raw'] = data.get('servo2_raw', None)
                result['servo3_raw'] = data.get('servo3_raw', None)
                result['servo4_raw'] = data.get('servo4_raw', None)

            self.graphDataUpdated.emit(result)

    @Slot(result=list)
    def getMessageFields(self):
        return self.message_fields

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

    @Slot()
    def showPidTunner(self):
        """PID Tunner 창을 띄우는 슬롯"""
        self.pid_tunner_window.show()
