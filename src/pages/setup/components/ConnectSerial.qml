import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

ColumnLayout {
    id: connectSerialRoot
    anchors.fill: parent

    property string connectionStatusText: "연결 대기"
    property color connectionStatusColor: "#555555"

    Component.onCompleted: {
        // 1초 후 포트 목록 업데이트
        startupTimer.start()
    }

    Timer {
        id: startupTimer
        interval: 400
        repeat: false
        onTriggered: updatePortList()
    }

    // 포트 목록 업데이트 함수
    function updatePortList() {
        if (typeof initializePortSelect !== 'undefined' && initializePortSelect !== null) {
            portComboBox.model = initializePortSelect.get_port_list() || []
        }
    }

    Text {
        text: "보드 연결"
        color: "#dddddd"
        font.pixelSize: 24
        font.bold: true
    }

    ColumnLayout {
        Layout.topMargin: 20

        // 포트 선택
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Port"
                color: "#999999"
                font.pixelSize: 14
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                ComboBox {
                    id: portComboBox
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 40
                    model: []
                    textRole: "display"
                    valueRole: "device"
                    currentIndex: -1
                }

                Button {
                    id: refreshButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40

                    background: Rectangle {
                        color: refreshButton.hovered ? "#666666" : "#555555"
                        radius: 6
                    }

                    Image {
                        source: "../../../assets/icons/refresh.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    onClicked: {
                        console.log("포트 목록 새로고침")
                        updatePortList()
                    }
                }
            }
        }

        // 보율 선택
        ColumnLayout {

            Layout.topMargin: 20
            spacing: 8

            Text {
                text: "Baud rate"
                color: "#999999"
                font.pixelSize: 14
                font.bold: true
            }
            ComboBox {
                id: baudRateComboBox
                Layout.preferredWidth: 300
                Layout.preferredHeight: 40
                model: [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200]
                currentIndex: 6
            }
        }

        Button {
            id: connectButton
            text: "연결"
            Layout.preferredWidth: 300
            Layout.preferredHeight: 40
            Layout.topMargin: 30
            background: Rectangle {
                color: connectButton.hovered ? "#66BB6A" : "#4CAF50"
                radius: 8
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: 14
                font.weight: 700
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // 버튼 클릭 시 Python의 connect_button_clicked 함수 호출
            onClicked: {
                if (portComboBox.currentIndex === -1) {
                    console.log("포트를 선택해주세요.");
                    return;
                }

                // 선택된 항목의 데이터와 보율을 인자로 전달
                initializePortSelect.connect_button_clicked(
                    portComboBox.model[portComboBox.currentIndex].device,
                    baudRateComboBox.currentValue
                )
            }
        }

        Rectangle {
            id: connectResult
            Layout.preferredWidth: 300
            Layout.preferredHeight: 40
            Layout.topMargin: 10 // 버튼과의 간격 조정

            color: connectSerialRoot.connectionStatusColor
            radius: 8
            
            Behavior on color {
                ColorAnimation { duration: 300 }
            }

            Text {
                text: connectSerialRoot.connectionStatusText
                color: "white"
                font.pixelSize: 14
                font.weight: 700
                anchors.centerIn: parent
            }
        }
        Connections {
            target: initializePortSelect
            function onConnectionResult(is_success, message) {
                connectSerialRoot.connectionStatusText = message
                connectSerialRoot.connectionStatusColor = is_success ? "#2196F3" : "#F44336" // 파랑(성공), 빨강(실패)
            }
        }
    }

    // 여백
    Item { Layout.fillHeight: true }
}