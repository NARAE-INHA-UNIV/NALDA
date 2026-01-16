## 사전 준비
코드를 컴파일하고 실행하기 전에, 컴패니언 컴퓨터(os는 우분투라고 가정함)에 GStreamer 관련 필수 패키지들을 설치

`
sudo apt update
 `
 
 `
sudo apt install build-essential pkg-config libgstreamer1.0-dev libgstrtspserver-1.0-dev 
gstreamer1.0-plugins-good gstreamer1.0-libav
 `




## RTSP 송출 서버 (rtsp_server.c)
 RTSP 스트림을 GCS와 같은 다른 클라이언트가 접속할 수 있도록 새로운 RTSP 서버를 열어 인코딩 및 송출함
 
 * ### 컴파일 명령어 
    `
    gcc rtsp_server.c -o rtsp_server $(pkg-config --cflags --libs gstreamer-1.0 gstreamer-rtsp-server-1.0 gio-2.0)
    `

## 단순 RTSP 재생 클라이언트 (rtsp_server.c 하단 주석처리)
안드로이드폰에 rtspsrc로 스트림에 직접 접속하여 성공하면 화면에 안드로이드폰이 송출한 영상을 우분투 pc에 띄움. 
* GCS측으로 영상데이터를 전송하지 않고, 컴패니언 컴퓨터에서만 영상데이터 수신이 되는, 단순한 테스트용 코드임.

* ### 컴파일 명령어 
    `
    gcc rtsp_server.c -o rtsp_server $(pkg-config --cflags --libs gstreamer-1.0 gstreamer-rtsp-server-1.0 gio-2.0)
    (상동)
    `


## 기록

* 테스트용으로, 안드로이드폰의 'IP Webcam'과 같은 영상스트리밍 앱을 소스로 사용하여 GCS NALDA 어플리케이션의 영상 스트리밍 기능을 테스트함.
 
    *  이 경우에는 rtsp_server.c의 실행은 필요 없고, 휴대폰의 영상 스트리밍 앱에 표시 된 출력 목표 Url을 단순히 Camera/index.qml의 testCameraUrl에 넣어주면 휴대폰으로 촬영한 영상소스가 GCS NALDA 어플리케이션에 정상 재생 됨 (핸드폰 앱에서의 해상도/프레임률 조정 필요할 수 있음)

        * 안드로이드폰의 IP Webcam으로 촬영한 영상을 rtsp_server는 중계자로써 GCS NALDA앱에 재송출 하는 코드를 작성하였었다.

            GCS측에서 서버로의 접속은 잘되었으나

            `
            qt.multimedia.ffmpeg.mediadataholder: Could not open
            media. FFmpeg error description: "Invalid data found when processing input" 
            `

            에러가 계속 발생하여 안드로이드폰으로 촬영한 영상이 GCS NALDA앱에 표시되지 않았었다.

            맨 위에서 언급했던 것 처럼 재송출 과정없이 IP Webcam앱에 적힌 url을 QML의 영상소스로 직접 사용하면, 정상적으로 휴대폰으로 촬영한 영상이 GCS NALDA앱에 스트리밍된다. 