import os
import sys
from pynput import keyboard
import questionary
import serial.tools.list_ports

CLI_NAME = "MiniLink"


class UserInputHandler():
    port = None
    baudrate = None
    msg = None

    msgList: dict
    pressed_keys = set()  # pynput을 위한 현재 눌린 키들을 추적

    flags: dict = {"print": True, "log": True}

    def __init__(self):
        # pynput 키보드 리스너 설정
        self.listener = keyboard.Listener(
            on_press=self._on_key_press,
            on_release=self._on_key_release
        )
        self.listener.start()
        return

    def chooseInit(self):
        try:
            self.port = self.__choose_port_init()
            self.baudrate = self.__choose_baudrate_init()

        except Exception as err:
            print(err)
            self.chooseInit()

        return [self.port, self.baudrate]

    # choose_port()
    # @detail : COM 포트 장치 목록을 로딩해서 선택한다.
    # @return : 선택된 장치의 COM 포트 (on Unix device file path) : str
    def choose_port(self, addition_item=None):
        lists = [f"{port.device} - {port.description}" for port in serial.tools.list_ports.comports()]

        if (addition_item != None):
            lists.append(addition_item)

        answer = questionary.select(
            "Choose Serial Port :",
            choices=lists
        ).ask()

        if answer in addition_item:
            return answer

        return answer.split(" - ")[0]

    # choose_baudrate()
    # @detail : COM 포트의 보드레이트 선택
    # @retrun : baud rate : int
    def choose_baudrate(self, addition_item=None):
        lists = ['9600', '57600', '115200']

        if (addition_item != None):
            for i in addition_item:
                lists.append(i)

        answer = questionary.select(
            "Choose baudrate :",
            default='57600',
            choices=lists
        ).ask()

        if answer in addition_item:
            return answer

        return int(answer)

    # updateMessageList()
    # @detail : Message 선택지 목록을 갱신한다.
    def updateMessageList(self, msgList: dict):
        self.msgList = msgList
        return

    # chooseMessage()
    # @detail : 화면에 출력할 Message를 선택한다.
    # @require : updateMessageList() 최초 실행
    def chooseMessage(self, addition_item=None):
        lists = [f"{handler[0]} : {handler[1][0]}" for handler in list(self.msgList.items())]

        if (addition_item != None):
            lists.append(addition_item)

        answer = questionary.select(
            "Choose MSG :",
            choices=lists
        ).ask()

        if addition_item != None and answer in addition_item:
            return answer

        return int(answer.split(" : ")[0])

    # __choose_port_init
    def __choose_port_init(self):
        answer = self.choose_port("a) QUIT")

        if (answer == "a) QUIT"):
            exit()

        return answer.split(" - ")[0]

    # __choose_baudrate_init
    def __choose_baudrate_init(self):
        answer = self.choose_baudrate(["a) MANNUAL INPUT", "b) ../"])

        match(answer):
            case "a) MANNUAL INPUT":
                try:
                    answer = int(input("INPUT baud rate :"))
                    return int(answer)

                except ValueError:
                    print(f"[{CLI_NAME}] Input integer only.")

                except Exception as err:
                    print(err)

            case "b) ../":
                self.port = self.__choose_port_init()

            case _:
                return int(answer)

        return self.__choose_baudrate_init()

    # _on_key_press
    # @detail : 키를 누르면 pressed_keys에 추가
    def _on_key_press(self, key):
        """pynput 키 press 이벤트 핸들러"""
        try:
            self.pressed_keys.add(key.char)
        except AttributeError:
            # 특수 키의 경우
            self.pressed_keys.add(key)

    # _on_key_release
    # @detail : 키를 놓으면 pressed_keys에서 제거
    def _on_key_release(self, key):
        """pynput 키 release 이벤트 핸들러"""
        try:
            self.pressed_keys.discard(key.char)
        except AttributeError:
            # 특수 키의 경우
            self.pressed_keys.discard(key)

    # _is_key_pressed
    # @detail : 특정 키가 눌려있는지 확인
    def _is_key_pressed(self, key_char):
        """특정 키가 눌려있는지 확인"""
        return key_char in self.pressed_keys

    # whileInputHandler()
    # @detail : main.py의 while문 내에서 입력과 관련된 처리를 담당하는 Handler
    # @return : ['code', [data]]
    def whileInputHandler(self):
        if self._is_key_pressed('q'):
            sys.exit()
        elif self._is_key_pressed('s'):
            return ['chg_msg', self.chooseMessage()]
        elif not self._is_key_pressed('m'):
            return [None, None]

        lists: list = [
            "s) Change message",
            "t) Send message",
            "q) QUIT",
            "x) ../"
        ]

        answer = questionary.select(
            "MENU :",
            choices=lists
        ).ask()

        match(answer):
            case "s) Change message": return ['chg_msg', self.chooseMessage()]
            case "t) Send message": return ['send_msg', self.input_msg_mannaul()]
            case "q) QUIT": sys.exit()
            case "x) ../": return [None, None]

    def input_msg_mannaul(self):
        '''
        # input_msg_mannaul()
        전송할 값을 수동으로 입력 받는 메소드

        Params :

        Returns :
            `list` `[msg_id, payload]`
            msg_id `int`  - Message ID
            payload `list` - payload data
        '''

        print(f"[{CLI_NAME}] Input an value as integer")

        msg_id: int = None
        while msg_id == None or (msg_id < 0 or msg_id > 65536):
            msg_id = self.__input_int(f"[{CLI_NAME}] MSG ID : ")

        print(f"[{CLI_NAME}] Input 'x' if you want to end")
        tmp: int = None
        payload: list = []

        while True:
            tmp = self.__input_int(f"[{CLI_NAME}] Payload ({len(payload)}) : ", "x")

            if tmp == "x":
                break

            if tmp == None or (tmp < 0 or tmp > 255):
                continue

            payload.append(tmp)
            tmp = None

        return [msg_id, payload]

    # __input_int
    # @detail : 정수 값만 입력 받는 메소드
    def __input_int(self, text: str, endCode: str = None):
        try:
            data = input(text)
            if (endCode == data):
                return endCode
            return int(data)

        except ValueError:
            print(f"[{CLI_NAME}] Input integer only.")
            return self.__input_int(text, endCode)

        except Exception as err:
            print(err)
            return self.__input_int(text, endCode)
