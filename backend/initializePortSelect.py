import serial.tools.list_ports
import threading
import time

from PySide6.QtCore import QObject, Signal, Slot


# QML과 통신을 담당할 백엔드 클래스
class InitializePortSelect(QObject):
    connectionResult = Signal(bool, str)  # (성공여부, 메시지)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.port_list = []
        self.ser = None  # 시리얼 객체 보관
        self.monitor_thread = None
        self.monitoring = False


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
    def connect_button_clicked(self, device, baudrate):
        print("--- Python: 연결 버튼 클릭됨 ---")
        if not device:
            print("오류: 포트가 선택되지 않았습니다.")
            return

        print(f"Port: {device}, Baud rate: {baudrate}")
        try:
            ser = serial.Serial(device, baudrate)
            #이 serial.Serial()은 실제로 연결됐는지 확인하는 코드가 아니다. 시리얼 포트를 여는 코드일 뿐이다. 
            self.ser = ser  # 시리얼 객체 저장
            print(f"{device}에 성공적으로 연결되었습니다.")
            #임시용으로 연결 성공을 가정한 것일 뿐

            #####실제로 연결하는 코드 작성 필요 [하기 이유로 아직 미작성]
            #FC(STM32)에서 연결 응답을 주는 방식을 정할 필요가 있다
            #1. imu값 읽히는 지, 읽힌다면 바로 연결 성공으로 판단 (FC Github에 있는 ReadData_python 사용 필요)
                # ->어차피 GCS에서 imu값을 읽어야할 필요가 있기에 1번을 사용하는 것이 나을 것인데, 아마 1번에 2번내용이  이미 구현되어있을 것이다.
            #2. FC의 STM32 펌웨어쪽에서 직접 연결 성공에대한 응답을 UART로 주는 방식 (FC STM 펌웨어코딩 및 연결해볼필요 있지만 아직 커넥터를 못받았다...)
            
            #####연결 성공 시 QML 변화 trigger
            self.connectionResult.emit(True, f"{device} : 연결 성공")
            
            # 연결 성공 시 모니터링 시작
            self.start_monitoring_disconnect()

        except Exception as e:
            print(f"연결 실패: {e}")
            
            #####연결 실패 시 QML 변화 trigger
            self.connectionResult.emit(False, f"연결 실패: {e}")


    # 연결 끊김 모니터링 기능 추가 
    def start_monitoring_disconnect(self):
        if self.monitoring:
            return  # 이미 모니터링 중이면 중복 실행 방지
        self.monitoring = True
        def monitor():
            while self.monitoring:
                try:
                    if self.ser is not None:
                        self.ser.read(1)  # 데이터가 없어도 timeout 후 예외 발생 가능
                except serial.SerialException:
                    print("[Monitor] 연결 끊김 감지!")
                    self.connectionResult.emit(False, f"{device} : 연결 끊김, 연결 대기 중...")
                    self.monitoring = False
                    break
                except Exception as e:
                    print(f"[Monitor] 기타 예외: {e}")
                time.sleep(1)  # 1초마다 체크
        t = threading.Thread(target=monitor, daemon=True)
        t.start()
        self.monitor_thread = t


