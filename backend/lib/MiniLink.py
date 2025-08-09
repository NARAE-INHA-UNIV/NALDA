import os
import sys
import serial
import numpy

from .xmlHandler import XmlHandler
from .Log import *


MINILINK_VERSION = 0xFA
CLI_NAME = "MiniLink"


class MiniLink():
    ser: serial = None
    packet = {
        'Header': 0, 'Length': 0, 'SEQ': 0, 'MSG ID': 0,
        'data': numpy.zeros(1024, int),
        'CRC': 0
    }
    __cnt: int = 0
    __MSG_ID: int = None

    xmlHandler = XmlHandler()

    msgs_dict: dict = {}
    msgs_dict_ori: dict = {}

    def __init__(self):
        self.xmlHandler.loadMessageListFromXML(self.msgs_dict_ori)
        return

    def connect(self, port, baudrate: int = 115200, MSG_ID: int = None):
        '''
        # connect()
        장치에 연결한다.

        Params :
            port - 연결할 포트
            baudrate `int` - 보드레이트 (default 115200)
            (optical) MSG_ID `int` - Message ID

        Returns :
            0 - 선택됨
            -1 - 유효하지 않은 메세지 번호
        '''

        try:
            self.ser = serial.Serial(port, baudrate, timeout=1)
            self.__cnt = 0
            print(f"[{CLI_NAME}] Connected to %s (%d)" % (port, baudrate))

            if (MSG_ID != None):
                self.chooseMessage(MSG_ID)

            self.updateMessageList()

            print(f"[{CLI_NAME}] Press 'm' key to open the memu.")
            return 0

        except Exception as err:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            exit()

    def chooseMessage(self, id: int):
        '''
        # chooseMessage()
        화면에 표시할 메세지를 선택한다.
        갱신하는 함수는 `updateMessageList()`

        Params :
            id `int` - Message ID

        Returns :
            0 - 선택됨
            1 - 유효하지 않은 메세지 번호
        '''

        if id not in list(self.msgs_dict.keys()):
            print(f"[{CLI_NAME}] invaild message id")
            return 1

        print(self.xmlHandler.getMessageColumnNames(id))
        self.__MSG_ID = id

        return 0

    def getIDfromName(self, name: str):
        '''
        # getIDfromName()
        name으로부터 message의 ID를 구한다.

        Params :
            name `str` - message의 이름
        Returns :
            id `int` - message의 id
            None - 값이 없을 때
        '''

        lists: list = self.getMessageList(selectId=True, selectNames=True)
        if (name not in lists[1]):
            return None

        return lists[0][lists[1].index(name)]

    def getMessageFrequency(self, id: int = None):
        '''
        # getMessageFrequency()
        수신 받은 message의 빈도를 출력한다.

        Params :
            (optical) id `int` - Message ID
        Returns :
            (default) `[names, counts]`
            (others) `counts`
            names `list` - message의 이름
            counts `list` - message의 빈도 값
        '''

        if (id and id in self.getMessageList(selectId=True)):
            return self.msgs_dict[id][2]

        return self.getMessageList(selectNames=True, selectCounts=True)

    def getMessageList(self, selectId: bool = False, selectNames: bool = False, selectCounts: bool = False):
        '''
        # getmessagelist()
        수신 받은 message의 목록을 반환한다.
        갱신하는 함수는 `updatemessagelist()`

        params :
            (optical) selectid `bool` - msg id 값을 리스트로 반환
            (optical) selectnames `bool` -  message의 이름 값을 리스트로 반환
            (optical) selectcounts `bool` -  message의 총 빈도 값을 리스트로 반환
        returns :
            (default) self.msgs_dict `dict` `{ id : [ name, instance, count ] }`
            (selectid) data `list` `[ids]`
            (selectname) data `list` `[names]`
            (selectcounts) data `list` `[couts]`
            (selectid|selectname) data `list` `[id, names]`
        '''

        if ((selectId | selectNames | selectCounts) == False):
            return self.msgs_dict

        data: list = []
        if (selectId):
            data.append(list(self.msgs_dict.keys()))
        if (selectNames):
            data.append([i[0] for i in self.msgs_dict.values()])
        if (selectCounts):
            data.append([i[2] for i in self.msgs_dict.values()])

        # 만약 값이 하나면 1차원 리스트로 반환
        if (len(data) == 1):
            data = data[0]

        return data

    def getMessageName(self, id: int = None):
        '''
        # getMessageName()
        Message의 이름을 반환한다.

        Params :
            id `int` - 원하는 MSG ID. 기본값은 None(현재 반환하는 값)
        Returns :
            name `str`
        '''
        if (id != None):
            msg_id: int = id
        else:
            msg_id: int = self.__MSG_ID

        return self.xmlHandler.getMessageName(msg_id)

    def getMessageColumnNames(self, id: int = None):
        '''
        # getMessageColumnNames()
        Message의 속성들의 이름 출력한다.

        Params :
            id `int` - 원하는 MSG ID. 기본값은 None(현재 반환하는 값)
        Returns :
            name `list(str)`
        '''

        if (id != None):
            msg_id: int = id
        else:
            msg_id: int = self.__MSG_ID

        return self.xmlHandler.getMessageColumnNames(msg_id)

    def getMessageColumnTypes(self, id: int = None):
        '''
        # getMessageColumnTypes()
        Message의 속성들의 타입 출력한다.

        Params :
            id `int` - 원하는 MSG ID. 기본값은 None(현재 반환하는 값)
        Returns :
            name `list(str)`
        '''

        if (id != None):
            msg_id: int = id
        else:
            msg_id: int = self.__MSG_ID

        return self.xmlHandler.getMessageColumnTypes(msg_id)

    def getPayload(self):
        '''
        ## getPayload()
        수신 받은 패킷 중 Payload 부분만 출력한다.

        Returns :
            Payload `list`
        '''
        data: numpy.array = self.packet['data']
        length: int = self.packet['Length']

        return data[5:length-2]

    def read(self, enPrint: bool = False, enLog: bool = False):
        '''
        # read()
        한 패킷을 수신한다.

        Params :
            enPrint `bool` - print 유무
            enLog `bool` - Log 저장 유무

        Returns :
            unpacked_data `list` - 자료형에 맞게 가공된 payload
            None - 원하는 메세지가 아닐 때
        '''

        if (self.__readByte(self.packet) != 0):
            return None

        data: numpy.array = self.packet['data']
        length: int = self.packet['Length']
        msg_id = data[3] | data[4] << 8
        payload: numpy.array = self.getPayload()

        self.packet['SEQ'] = data[2]
        self.packet['MSG ID'] = msg_id

        if (msg_id not in list(self.msgs_dict.keys())):
            self.msgs_dict.update({msg_id: self.msgs_dict_ori[msg_id]})

        self.msgs_dict[msg_id][2] = self.msgs_dict[msg_id][2] + 1

        # Log
        if (enLog == True):
            messageName: str = self.xmlHandler.getMessageName(msg_id)

            saveLogFromList("packet-raw", data[:length], isHex=True)
            saveLogFromList("msg_frequency", self.getMessageFrequency()[1], columnName=self.getMessageFrequency()[0])
            saveLogFromList(f"{messageName}", self.xmlHandler.parser(msg_id, payload),
                            columnName=self.xmlHandler.getMessageColumnNames(msg_id))

        # print or return only selected value
        if (self.__MSG_ID != self.packet['MSG ID']):
            return None

        unpacked_data: list = self.xmlHandler.parser(self.__MSG_ID, payload)

        if (enPrint == True):
            print(unpacked_data)

        return unpacked_data

    def send(self, data: list):
        '''
        # send()
        FC에 message 전송한다.

        Params :
            data `list` 
            [MSG ID, [Payload]]

        Returns :
            0 : 정상 송신
            1 : 송신 에러
        '''

        try:
            self.packet['SEQ'] = self.packet['SEQ'] + 1

            tx: list = [MINILINK_VERSION]
            tx.append(7+len(data[1]))
            tx.append(int(self.packet['SEQ']))
            tx = tx + [(int(data[0]) & 0xff), (int(data[0]) >> 8)]
            tx = tx + data[1]

            crc = int(self.__calculate_crc(tx, len(tx)+2))
            tx = tx + [(crc >> 8), (crc & 0xff)]

            self.ser.write(bytes(tx))
            print(f"[{CLI_NAME}] send : ", tx)

            return 0

        except Exception as err:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            return 1

    def updateMessageList(self):
        '''
        # updateMessageList()
        수신 받은 Message의 목록을 갱신하고 반환 한다.

        Returns :
            self.msgs_dict `dict`
            {id:[name, instance, count]}
        '''
        try:
            print(f"[{CLI_NAME}] Loading the messages...")

            while 1:
                if (self.__readByte(self.packet) != 0):
                    continue
                data: numpy.array = self.packet['data']
                msg_id: int = data[3] | data[4] << 8

                self.packet['SEQ'] = int(data[2])
                self.packet['MSG ID'] = int(msg_id)

                if (msg_id in list(self.msgs_dict.keys())):
                    print(f"[{CLI_NAME}] Found {len(list(self.msgs_dict.keys()))} messages!")
                    break

                self.msgs_dict.update({int(msg_id): self.msgs_dict_ori[msg_id]})

            return self.msgs_dict

        except Exception as err:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)

    def __calculate_crc(self, data, length):
        crc: numpy.uint16 = 0x0000
        for i in range(0, length - 2):
            crc ^= numpy.uint16(data[i] << 8)
            for j in range(0, 8):
                if (crc & 0x8000):
                    crc = (crc << 1) ^ 0x1021
                else:
                    crc = (crc << 1)

        return crc & 0xffff

    def __checkCRC(self):
        length: int = self.packet['Length']
        data: numpy.array = self.packet['data']

        rxCRC = data[length-1] << 8 | data[length-2]
        retval = self.__calculate_crc(data, length)

        return retval == rxCRC

    def __byte2int(self, x):
        return int("0x"+str(x), 16)

    def __readByte(self, packet: dict):
        '''
        # __readByte()
        byte 단위로 데이터 받아옴

        Returns :
            -1 - 한 바이트를 정상 수신함.
            0 - 한 패킷을 정상 수신함.
            1 - 한 패킷을 정상 수신하였으나 CRC 오류.
            2 - 패킷의 길이 오류
            3 - 패킷이 MiniLink가 아님
            4 - 입력 값이 바이트가 아님
        '''

        try:
            data: numpy.array = packet['data']

            rx_byte = self.ser.read()  # 1바이트씩 읽기
            if (rx_byte == b''):
                return 4

            if (self.__cnt >= len(data)):
                print(f"{CLI_NAME} Have to increase Buffer size! {len(data)}")
                self.__cnt = 0

            data[self.__cnt] = self.__byte2int(rx_byte.hex())

            match(self.__cnt):
                case 0:
                    if data[self.__cnt] not in [MINILINK_VERSION, 0xFD, 0xFE]:
                        self.__cnt = 0
                        return 3
                case 1:
                    packet['Length'] = data[self.__cnt]
                case _:
                    if (self.__cnt == packet['Length'] - 1):
                        self.__cnt = 0
                        if (packet['Length'] > 0 and self.__checkCRC()):
                            return 0
                        return 1

                    elif (self.__cnt > packet['Length'] - 1):
                        return 2

            self.__cnt = self.__cnt + 1

        except Exception as e:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            sys.exit(0)

        return -1
