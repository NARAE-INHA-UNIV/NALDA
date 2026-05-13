import threading
import functools
import http.server
from PySide6.QtCore import QObject, Slot

from .utils import resource_path


class PlanMapServer(QObject):
    """Plan 페이지용 로컬 HTTP 서버.

    Kakao Maps SDK는 file:// 컨텍스트에서 로드 불가 (CORS / 도메인 검증).
    frontend/ 디렉토리를 http://127.0.0.1:PORT 로 서빙한다.
    """

    PORT = 18765

    def __init__(self):
        super().__init__()
        frontend_dir = resource_path("frontend")
        handler = functools.partial(
            http.server.SimpleHTTPRequestHandler,
            directory=frontend_dir
        )
        self._server = http.server.HTTPServer(("127.0.0.1", self.PORT), handler)
        thread = threading.Thread(target=self._server.serve_forever, daemon=True)
        thread.start()

    @Slot(result=str)
    def mapUrl(self):
        return f"http://127.0.0.1:{self.PORT}/pages/plan/kakaomap.html"
