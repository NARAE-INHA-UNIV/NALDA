import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

Rectangle {
    id: videoStream
    color: "#1a1a1a"

    // 카메라 타입을 결정하는 프로퍼티
    // "forward"(전방) 또는 "downward"(하방) 값을 가짐
    // 버튼 클릭 시 이 값이 바뀌고, 아래 streamUrl이 자동으로 갱신됨
    property string cameraType: "forward"

    // [테스트용 Url] IOS나 ANDROID 핸드폰에 존재하던 영상송출 앱을 활용하면 아래 주소만 적어도 영상이 출력됨. 
    property string testCameraUrl: "rtsp://172.30.1.23:8080/h264_ulaw.sdp"

        // 현재 선택된 카메라에 따라 영상 소스가 자동으로 바뀜
        // QML의 property 바인딩(자동 연결)으로, cameraType이 바뀌면 streamUrl도 자동 변경
        property string forwardCameraUrl: "rtsp://172.30.1.32:8554/forward_stream"
        property string downwardCameraUrl: "rtsp://172.30.1.32:8554/downward_stream"
        // TODO ** GStreamer또는 FFmpeg서버를 구축 후 기체에 달린 카메라로부터 데이터를 받아올 때 아래 Url을 사용 
        property string streamUrl: cameraType === "forward" ? forwardCameraUrl : downwardCameraUrl

    // 카메라 타입 변경 시 로그 출력
    onCameraTypeChanged: {
        console.log("카메라 전환:", cameraType === "forward" ? "전방 카메라" : "하방 카메라");
        console.log("스트림 URL:", streamUrl);
    }

    // 영상 및 오버레이 UI
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        radius: 8

        // 실제 영상 출력
        Video {
            id: videoDisplay
            anchors.fill: parent
            source: testCameraUrl //TODO 서버 구축후 streamUrl로 변경 
            autoPlay: true
        }

        // 영상 재생 상태 표시 (녹색: 재생중, 빨강: 정지/에러)
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: 10
            height: 10
            radius: 5
            color: videoDisplay.playbackState === Video.PlayingState ? "#4CAF50" : "#F44336"
            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }

        // 카메라 전환 버튼 오버레이
        // 영상 위에 반투명 배경으로 버튼을 띄움
        // 버튼 클릭 시 cameraType이 바뀌고, 이에 따라 영상이 자동 전환됨
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160
            height: 45
            radius: 8
            color: "#222222"
            opacity: 0.7
            z: 2

            RowLayout {
                anchors.centerIn: parent
                anchors.margins: 5

                // 전방 카메라 선택 버튼
                Button {
                    id: forwardButton
                    text: "전방"
                    Layout.fillWidth: true
                    highlighted: videoStream.cameraType === "forward"
                    onClicked: {
                        videoStream.cameraType = "forward";
                        console.log("전방 카메라 버튼 클릭됨");
                    }
                    background: Rectangle {
                        color: forwardButton.highlighted ? "#4CAF50" : "#555555"
                        radius: 6
                        opacity: 0.9
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 14
                        font.weight: 700
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // 하방 카메라 선택 버튼
                Button {
                    id: downwardButton
                    text: "하방"
                    Layout.fillWidth: true
                    highlighted: videoStream.cameraType === "downward"
                    onClicked: {
                        videoStream.cameraType = "downward";
                        console.log("하방 카메라 버튼 클릭됨");
                    }
                    background: Rectangle {
                        color: downwardButton.highlighted ? "#4CAF50" : "#555555"
                        radius: 6
                        opacity: 0.9
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 14
                        font.weight: 700
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
