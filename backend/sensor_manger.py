import random

from PySide6.QtCore import QObject, Signal, QTimer
from datetime import datetime


class SensorManager(QObject):
    dataReady = Signal(list)

    def __init__(self):
        super().__init__()
        self.timer = QTimer()
        self.timer.timeout.connect(self.generate_data)
        self.timer.start(100)  # 100ms마다 데이터 생성

    def generate_data(self):
        # 테스트용 배열 데이터 생성
        timestamp = int(datetime.now().timestamp() * 1000)
        data = random.randint(1, 100)
        # print(f"Python에서 생성한 데이터: {data}")
        self.dataReady.emit([timestamp, data])
