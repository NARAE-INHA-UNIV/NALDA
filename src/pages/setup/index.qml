import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: setupComponent
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: "#1a1a1a"

    property string connectionStatusText: "연결 대기"
    property color connectionStatusColor: "#555555"

    property var menuItems: [
        { id: 1, name: "보드 연결", page: "SETUP" },
        { id: 2, name: "다음 메뉴", page: "MENU" },
        { id: 3, name: "다음 메뉴", page: "MENU" },
        { id: 4, name: "다음 메뉴", page: "MENU" },
        { id: 5, name: "다음 메뉴", page: "MENU" },
        { id: 6, name: "다음 메뉴", page: "MENU" }
    ]
    property int selectedPageId: 1


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


    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        color: "#2a2a2a"
        radius: 8

        RowLayout{
            anchors.fill: parent
            spacing: 10

            // 설정 사이드바
            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                Layout.margins: 20
                color: "#2a2a2a"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Repeater {
                        id: menuRepeater
                        model: setupComponent.menuItems

                        delegate: Rectangle {
                            id: menuItem
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            radius: 8
                            color: setupComponent.selectedPageId === menuItem.modelData.id ? "#3a3a3a" : "#2a2a2a"

                            function updateColor() {
                                if (setupComponent.selectedPageId === menuItem.modelData.id) {
                                    color = "#1a1a1a"
                                } else {
                                    color = "#2a2a2a"
                                }
                            }

                            Text {
                                text: modelData.name
                                color: "#dddddd"
                                font.pixelSize: 16
                                font.weight: 600
                                anchors.centerIn: parent
                            }
                        }
                    }

                    // 여백
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // 컨텐츠 영역
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                color: "#2a2a2a"

                ColumnLayout {
                    anchors.fill: parent

                    Text {
                        text: "보드 연결"
                        color: "white"
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
                                        source: "../../assets/icons/refresh.svg"
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
                                currentIndex: 0
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

                            color: setupComponent.connectionStatusColor
                            radius: 8
                            
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }

                            Text {
                                text: setupComponent.connectionStatusText
                                color: "white"
                                font.pixelSize: 14
                                font.weight: 700
                                anchors.centerIn: parent
                            }
                        }
                        Connections {
                            target: initializePortSelect
                            function onConnectionResult(success, message) {
                                setupComponent.connectionStatusText = message
                                setupComponent.connectionStatusColor = success ? "#2196F3" : "#F44336" // 파랑(성공), 빨강(실패)
                            }
                        }
                    }

                    // 여백
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
