import os
import sys
import datetime

name_history : dict = {}

def saveLog(name:str, data:str, columnName=None):
    '''
    # saveLog()
    로그 파일을 저장.
    파일 제목에 프로그램을 실행한 시간이 접두사로 붙음.

    Params :
        name `str` - 파일 제목
        data `str` - 저장할 데이터
        columnName `list` - 데이터의 속성명
    '''

    try:
        if(os.path.isdir("./log") == False):
            os.makedirs("./log")

        # check log.csv already existed
        if name not in list(name_history.keys()):
            now = datetime.datetime.now().strftime('%Y-%m-%d(%H_%M_%S)')
            file_name : str = f"{now}-{name}.csv"

            name_history.update({name:file_name})

            if(columnName != None):
                data = f"{columnName}\n{data}"
        else :
            file_name = name_history[name]
        
        with open(f"./log/{file_name}", 'a') as fp:
            fp.write(data)
            fp.write('\n')

    except Exception as err:
        print(err)


def saveLogFromList(name:str, data:list, columnName:list=None, isHex:bool=False):
    '''
    # saveLogFromList()
    data가 `list`로 주어질 때, `str`로 변환해서 저장
    `saveLog()` 함수 호출

    Params :
        name `str` - 파일 제목
        data `list` - 저장할 데이터
        columnName `list` - 데이터의 속성명
        isHex `bool` - 데이터의 16진수 유무
    '''

    try:
        now = datetime.datetime.now().strftime('%Y-%m-%d(%H_%M_%S)')

        # formatting Hex
        if(isHex == False):
            log :str = f"{now},{','.join(map(str,data))}"
        else:
            log :str = f"{now},"
            for i in data:
                log = log + "%02x,"%i

        if(columnName!=None):
            columnName = f"timestamp,{','.join(columnName)}"

        saveLog(name, log, columnName)

    except Exception as err:
        exc_type, exc_obj, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)
        print(err)
