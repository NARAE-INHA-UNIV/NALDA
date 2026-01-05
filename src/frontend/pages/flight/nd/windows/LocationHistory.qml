import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: historyRoot
    width: 600
    height: 400
    color: "#2A2A2A"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 헤더
        Rectangle {
            // 배경색과 전체적인 레이아웃을 담당할 컨테이너
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "#3A3A3A"
            radius: 4

            // 그 안에 텍스트 정렬을 담당할 RowLayout
            RowLayout {
                anchors.fill: parent

                // 너비 계산 기준을 부모(RowLayout)로 변경하고, 마지막 열이 남은 공간을 채우도록 함
                Text {
                    text: "시점"
                    color: "white"
                    font.pixelSize: 14
                    Layout.preferredWidth: parent.width * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: "위도"
                    color: "white"
                    font.pixelSize: 14
                    Layout.preferredWidth: parent.width * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: "경도"
                    color: "white"
                    font.pixelSize: 14
                    Layout.preferredWidth: parent.width * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: "고도"
                    color: "white"
                    font.pixelSize: 14
                    Layout.preferredWidth: parent.width * 0.2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text: "방위각"
                    color: "white"
                    font.pixelSize: 14
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // 기록 리스트
        ListView {
            id: historyView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: gpsManager ? gpsManager.pathData : []

            delegate: Rectangle {
                width: historyView.width
                height: 35
                color: index % 2 === 0 ? "#4CAF50" : "#3E573F"

                RowLayout {
                    anchors.fill: parent

                    // 헤더와 동일한 너비 계산 방식 적용
                    Text { text: modelData.timestamp; color: "white"; Layout.preferredWidth: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 18}
                    Text { text: modelData.lat; color: "white"; Layout.preferredWidth: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14}
                    Text { text: modelData.lon; color: "white"; Layout.preferredWidth: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 }
                    Text { text: modelData.alt; color: "white"; Layout.preferredWidth: parent.width * 0.2; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 }
                    Text { text: modelData.hdg; color: "white"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        // 하단 버튼
        Button {
            // Layout에 의해 관리되므로 anchors.horizontalCenter 제거
            Layout.alignment: Qt.AlignRight
            text: "경로 기록 초기화"
            onClicked: {
                if(gpsManager) {
                    gpsManager.clearPath()
                }
            }
        }
    }
}
