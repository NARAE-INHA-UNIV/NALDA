import os
import numpy
import struct
import xml.etree.ElementTree as ET


class XmlHandler:
    fp = None
    root = None

    # {id:[name, addr, count]}
    msgs_dict: dict = None

    def __init__(self):
        self.__loadXML()

    # xml file load
    def __loadXML(self):
        # Get the directory where this file is located
        current_dir = os.path.dirname(os.path.abspath(__file__))
        xml_path = os.path.join(current_dir, "MSG", "common.xml")
        self.fp = open(xml_path, 'r')
        self.root = ET.fromstring(self.fp.read())

    def loadMessageListFromXML(self, msgs: dict):
        '''
        # loadMessageListFromXML()
        XML로부터 Message 목록을 모두 불러옴<br>
        MiniLink.__init__()에서 호출됨

        Param :
            msg `dict` - 데이터가 저장될 딕셔너리

        Returns :
            msg `dict`
        '''
        self.msgs_dict = msgs
        messages = self.root.find("messages").findall("message")

        for msg in messages:
            msgs.update({int(msg.get("id")): [msg.get("name"), msg, 0]})

        return msgs

    def getMessageName(self, id: int):
        '''
        # getMessageName()
        Message의 이름을 불러옴

        Param :
            id `int` - MSG ID

        Returns :
            name `str`
        '''

        name: str = self.msgs_dict[id][0]
        return name

    def getMessageInstance(self, id: int):
        '''
        # getMessageInstance()
        Message의 인스턴스(객체)를 불러옴

        Param :
            id `int` - MSG ID

        Returns :
            instance
        '''

        instance = self.msgs_dict[id][1]
        return instance

    def getMessageColumnTypes(self, id: int):
        '''
        # getMessageColumnTypes()
        Message의 구성요소들의 type 정보를 불러옴<br>
        관계형 DB에서 속성의 타입 출력과 동일.

        Param :
            id `int` - MSG ID

        Returns :
            data `list` - Column types
        '''

        data: list = []
        fields = self.getMessageInstance(id).findall("field")

        for field in fields:
            data.append(field.get("type"))

        return data

    def getMessageColumnNames(self, id: int):
        '''
        # getMessageColumnNames()
        Message의 구성요소들의 name 정보를 불러옴<br>
        관계형 DB에서 속성의 이름 출력과 동일.

        Param :
            id `int` - MSG ID

        Returns :
            data `list` - Column names
        '''

        data: list = []
        fields = self.getMessageInstance(id).findall("field")

        for field in fields:
            data.append(field.get("name"))

        return data

    def parser(self, id: int, payload: numpy.array):
        '''
        # parser()
        payload를 자료형의 크기에 맞게 나누어서 리스트로 반환함.

        Param :
            id `int` - MSG ID
            payload `numpy.array` - payload 데이터

        Returns :
            unpacked_data `list` - 가공된 ayload 데이터
        '''

        try:
            fields = self.getMessageInstance(id).findall("field")

            fmt: str = '<'
            for field in fields:
                match(field.get("type")):
                    case 'uint64_t': fmt = fmt+"Q"
                    case 'uint32_t': fmt = fmt+"I"
                    case 'uint16_t': fmt = fmt+"H"
                    case 'uint8_t': fmt = fmt+"B"

                    case 'int64_t': fmt = fmt+"q"
                    case 'int32_t': fmt = fmt+"i"
                    case 'int16_t': fmt = fmt+"h"
                    case 'uint8_t': fmt = fmt+"b"

                    case 'float': fmt = fmt+"f"
                    case 'double': fmt = fmt+"d"

            unpacked_data: list = list(struct.unpack(fmt, bytes(list(payload))))

            return unpacked_data

        except Exception as err:
            print(f"{err} ({len(payload)}) : ")
            for i in payload:
                print("%02x " % (i), end='')
            print("")
