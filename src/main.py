import os
import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QSplashScreen
from PySide6.QtGui import QFontDatabase, QFont, QPixmap, QIcon

from windows.main_window import MainWindow
from backend.utils import resource_path


# 환경 변수
os.environ['QML_XHR_ALLOW_FILE_READ'] = '1'         # QML에서 로컬 파일 읽기를 허용
os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Material'  # QML 스타일 설정 (Material)


def set_font(app):
    """메인 위젯뿐만 아니라 서브 위젯들도 동일한 폰트를 사용하도록 전역 폰트 설정"""

    font_path = resource_path("frontend/assets/fonts/PretendardVariable.ttf")
    font_id = QFontDatabase.addApplicationFont(font_path)
    if font_id != -1:
        family = QFontDatabase.applicationFontFamilies(font_id)[0]
        app.setFont(QFont(family))
    else:
        print("Pretendard 폰트 설정 실패")
        sys.exit(-1)


def main():
    app = QApplication(sys.argv)

    # 전역 폰트 설정
    set_font(app)

    # 아이콘 설정 (타이틀, 작업 표시줄)
    app.setWindowIcon(QIcon(resource_path("frontend/assets/app.ico")))

    # 스플래시 스크린 표시
    splash_pixmap = QPixmap(resource_path("frontend/assets/splash.png")).scaled(544, 308, Qt.KeepAspectRatio)
    splash = QSplashScreen(splash_pixmap)
    splash.show()
    app.processEvents()

    # 메인 윈도우
    window = MainWindow()
    window.show()
    splash.finish(window)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
