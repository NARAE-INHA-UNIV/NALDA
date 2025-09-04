테스트용으로, 안드로이드폰의 'IP Webcam' 앱을 영상 소스로 사용하여, GStreamer를 통해 RTSP 비디오 스트림을 다룸.

* rtsp_server.c는 영상송신부 서버코드로, raw영상데이터 송신부는 안드로이드 휴대폰으로 실험하였으나 다른것으로 바꿔도 코드 상 크게 달라질 부분은 없을것으로 예상함


## 사전 준비
코드를 컴파일하고 실행하기 전에, 컴패니언 컴퓨터(os는 우분투라고 가정함)에 GStreamer 관련 필수 패키지들을 설치

`
sudo apt update
 `
 
 `
sudo apt install build-essential pkg-config libgstreamer1.0-dev libgstrtspserver-1.0-dev 
gstreamer1.0-plugins-good gstreamer1.0-libav
 `




## RTSP 재송출 서버 (rtsp_server.c)
안드로이드폰에서 받은 RTSP 스트림을 GCS(PyQt프로그램)와 같은 다른 클라이언트가 접속할 수 있도록 새로운 RTSP 서버를 열어 재송출(Re-streaming)함


## 단순 RTSP 재생 클라이언트 (rtsp_server.c 하단 주석처리)
안드로이드폰에 rtspsrc로 스트림에 직접 접속하여 성공하면 화면에 안드로이드폰이 송출한 영상을 우분투 pc에 띄움. 
* GCS측으로 영상데이터를 전송하지 않고, 컴패니언 컴퓨터에서만 영상데이터 수신이 되는, 단순한 테스트용 코드임.