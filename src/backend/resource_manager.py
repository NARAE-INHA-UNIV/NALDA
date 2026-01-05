import os
from PySide6.QtCore import QObject, Slot
from .utils import resource_path


class ResourceManager(QObject):
    def __init__(self):
        super().__init__()
        # 추추에 빌드 시 qrc를 사용할 경우를 대비
        # 그렇지 않더라도 리소스 경로를 src 기준으로 일관되게 관리하기 위해
        self._prefix = resource_path("frontend")  # if is_dev_mode() else "qrc:/"

    @Slot(str, result=str)
    def getUrl(self, path):
        return 'file:///' + os.path.join(self._prefix, path)
