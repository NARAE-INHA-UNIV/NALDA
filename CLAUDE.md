# NALDA Architecture

## 기술 스택

- **Frontend**: QML (PyQt/PySide6 QQuickWidget)
- **Backend**: Python (PySide6)
- **통신**: MAVLink (pymavlink)

## 데이터 흐름

모든 MAVLink 메시지는 아래 단방향 흐름을 따른다.

```
serial_manager  →  backend manager  →  QML
(messageUpdated)   (get_data 슬롯)     (Connections)
```

### 규칙

- 프로토콜 파싱·변환은 전부 backend manager가 담당한다.
- QML은 backend manager가 emit한 의미 있는 신호만 수신한다.
- `serial_manager`는 연결 관리와 명령 전송 전용이며, 데이터 수신은 `messageUpdated` 신호 하나로 모든 manager에게 브로드캐스트한다.

### 예시

```python
# serial_manager.py
self.messageUpdated.emit(msg_id, msg_dict)   # 모든 메시지 브로드캐스트
```

```python
# flight_status_manager.py
class FlightStatusManager(QObject):
    heartbeatReceived = Signal(bool, int, int)   # QML이 구독할 신호

    @Slot(int, dict)
    def get_data(self, msg_id, data):            # messageUpdated 수신
        if msg_id == 0:
            self.heartbeatReceived.emit(...)
```

```qml
// etc-panels/index.qml
Connections {
    target: flightStatusManager                  // manager만 바라봄
    function onHeartbeatReceived(isArmed, ...) { ... }
}
```

## 새 Backend Manager 추가 방법

새로운 MAVLink 메시지를 처리하는 기능이 필요할 때는 아래 절차를 따른다.

### 1. `src/backend/` 에 매니저 파일 생성

```python
from PySide6.QtCore import QObject, Signal, Slot

class FooManager(QObject):
    someSignal = Signal(float)          # QML에 전달할 신호 정의

    @Slot(int, dict)
    def get_data(self, msg_id: int, data: dict):
        if msg_id != TARGET_ID:
            return
        self.someSignal.emit(data.get("field", 0.0))
```

### 2. `src/windows/main_window.py` 에 등록

`_setup_central_widget()` 안에서 세 가지를 추가한다.

```python
# ① 인스턴스 생성
self.foo_manager = FooManager()

# ② messageUpdated 연결
self.serial_manager.messageUpdated.connect(self.foo_manager.get_data)

# ③ QML context property 등록
context.setContextProperty("fooManager", self.foo_manager)
```

> **도크 위젯 전용 매니저**라면 `setContextProperty` 대신
> 해당 `DockableWidget` 의 `managers` 리스트에 `('fooManager', self.foo_manager)` 를 추가한다.

### 3. QML에서 수신

```qml
Connections {
    target: fooManager
    function onSomeSignal(value) { ... }
}
```

## QML 컨텍스트 범위

| 범위                      | 등록 위치                                  | 접근 가능한 QML              |
| ------------------------- | ------------------------------------------ | ---------------------------- |
| **전역** (central widget) | `main_window.py` `_setup_central_widget()` | `main.qml` 및 그 하위 페이지 |
| **도크 위젯**             | `DockableWidget` 생성 시 `managers` 인자   | 해당 도크의 QML만            |

현재 도크별 등록 현황:

```
PFD 도크      → pfdManager, serialManager
ND 도크       → gpsManager, resourceManager
Etc Panels 도크 → serialManager, gpsManager, flightStatusManager
Camera 도크   → (없음)
```

## `serialManager` 를 QML에서 직접 사용하는 경우

데이터 수신이 아닌 아래 두 가지 목적에만 허용한다.

1. **명령 전송** — `serialManager.sendArmCommand()`, `serialManager.setFlightMode()` 등
2. **명령 결과 수신** — `onCommandResult(command, success, message)`
3. **연결 관리** — `onConnectionResult`, `connectSerial()` 등 (`connect-serial` 페이지)
