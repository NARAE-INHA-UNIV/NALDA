import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 100

    property string alertTitle: ""
    property string alertMessage: ""

    Connections {
        target: statusTextManager
        function onStatusTextReceived(severity, text) {
            root.alertTitle = severity;
            root.alertMessage = text;
            root.visible = true;
        }
    }

    // 반투명 배경
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
    }

    // 알림 카드
    Rectangle {
        anchors.centerIn: parent
        width: 270
        height: cardColumn.implicitHeight
        color: "#1a1a1a"
        radius: 8

        Column {
            id: cardColumn
            width: parent.width
            spacing: 0

            // 제목 + 메시지 영역
            Item {
                width: parent.width
                height: titleText.implicitHeight + messageText.implicitHeight + 36

                Text {
                    id: titleText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 18
                    text: root.alertTitle
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    id: messageText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: titleText.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 8
                    text: root.alertMessage
                    color: "#e0e0e0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            // 버튼 영역
            Item {
                width: parent.width
                height: 62

                Button {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 15
                    anchors.bottomMargin: 8
                    width: 80
                    height: 46
                    text: "확인"

                    onClicked: {
                        root.visible = false;
                    }

                    background: Rectangle {
                        color: parent.down ? "#b71c1c" : "#d32f2f"
                        radius: 8
                        border.color: "#d32f2f"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 13
                        font.weight: 600
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
