import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import Styles 1.0

ColumnLayout {
    id: connectSerialRoot
    anchors.fill: parent

    property bool connectionStatusVisible: false
    property bool connectionStatusIsSuccess: false
    property bool connectionLoading: false

    property var portList: []

    Component.onCompleted: {
        // 초기화 작업
        Qt.callLater(function () {
            updatePortList();
            getCurrentConnection();
        });
    }

    Text {
        text: "보드 연결"
        color: Colors.textPrimary
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
                color: Colors.gray100
                font.pixelSize: 14
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 60

                ComboBox {
                    id: portComboBox
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 60
                    model: connectSerialRoot.portList
                    textRole: "device"
                    valueRole: "device"
                    currentIndex: 0
                    enabled: !(connectSerialRoot.connectionStatusIsSuccess || connectSerialRoot.connectionLoading)

                    delegate: ItemDelegate {
                        id: delegateItem
                        width: parent.width
                        height: 50

                        required property var model
                        required property int index

                        background: Rectangle {
                            anchors.fill: parent
                            color: delegateItem.hovered ? Colors.gray500 : "transparent"
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: delegateItem.model.device || ""
                                color: Colors.textPrimary
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                text: delegateItem.model.description || ""
                                color: Colors.gray100
                                font.pixelSize: 12
                            }
                        }

                        onClicked: {
                            portComboBox.currentIndex = index;
                            portComboBox.popup.close();
                        }
                    }

                    contentItem: Rectangle {
                        color: "transparent"

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            visible: portComboBox.currentIndex >= 0

                            Text {
                                text: portComboBox.currentIndex >= 0 ? (portComboBox.model[portComboBox.currentIndex]?.device || "") : ""
                                color: !(connectSerialRoot.connectionStatusIsSuccess || connectSerialRoot.connectionLoading) ? Colors.textPrimary : Colors.gray100
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                text: portComboBox.currentIndex >= 0 ? (portComboBox.model[portComboBox.currentIndex]?.description || "") : ""
                                color: Colors.gray100
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text: portComboBox.currentIndex === -1 ? "포트를 선택하세요" : ""
                            color: Colors.gray300
                            font.pixelSize: 14
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // 새로고침 버튼
                // Button은 자동 마진 때문에 간격 조절 안 되고, 크기 조절도 안 됨
                Rectangle {
                    id: refreshButton
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignBottom
                    radius: 6
                    color: refreshButton.enabled ? (refreshMouseArea.containsMouse ? Qt.darker(Colors.gray400, 1.1) : Colors.gray400) : Colors.gray600
                    enabled: !(connectSerialRoot.connectionStatusIsSuccess || connectSerialRoot.connectionLoading)

                    Image {
                        source: resourceManager.getUrl("assets/icons/serial/refresh.svg")
                        anchors.centerIn: parent
                        sourceSize.width: 20
                        sourceSize.height: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            updatePortList();
                        }
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
                color: Colors.gray100
                font.pixelSize: 14
                font.bold: true
            }

            ComboBox {
                id: baudRateComboBox
                Layout.preferredWidth: 300
                Layout.preferredHeight: 40
                model: [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200]
                currentIndex: 6
                enabled: !(connectSerialRoot.connectionStatusIsSuccess || connectSerialRoot.connectionLoading)
            }
        }

        ColumnLayout {
            Layout.topMargin: 30

            Button {
                id: connectButton
                Layout.preferredHeight: 50
                Layout.preferredWidth: 300
                text: connectSerialRoot.connectionLoading ? (connectSerialRoot.connectionStatusIsSuccess ? "연결 해제 중..." : "연결 중...") : (connectSerialRoot.connectionStatusIsSuccess ? "연결 해제하기" : "연결하기")
                enabled: !connectSerialRoot.connectionLoading // 연결 중일 때 비활성화
                background: Rectangle {
                    color: connectButton.enabled ? (connectSerialRoot.connectionStatusIsSuccess ? (mouseArea.containsMouse ? Qt.darker(Colors.red, 1.05) : Colors.red) : (mouseArea.containsMouse ? Qt.darker(Colors.green, 1.05) : Colors.green)) : Colors.gray600
                    radius: 8
                }
                contentItem: Text {
                    text: connectButton.text
                    color: Colors.textPrimary
                    font.pixelSize: 14
                    font.weight: 700
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (portComboBox.currentIndex === -1) {
                            console.log("포트를 선택해주세요.");
                            return;
                        }

                        // 버튼을 연결 중 상태로 변경
                        connectSerialRoot.connectionLoading = true;
                        connectSerialRoot.connectionStatusVisible = false;

                        // 0.5초 후에 연결 함수 실행
                        // UI 업데이트할 시간 확보
                        connectionTimer.start();
                    }
                }

                Timer {
                    id: connectionTimer
                    interval: 50
                    running: false
                    repeat: false
                    onTriggered: {
                        if (connectSerialRoot.connectionStatusIsSuccess) {
                            // 연결 해제
                            var res = serialManager.disconnectSerial();
                            if (res) {
                                console.log("연결이 해제되었습니다.");
                                connectSerialRoot.connectionStatusIsSuccess = false;
                            } else {
                                console.log("연결 해제에 실패했습니다.");
                            }
                            connectSerialRoot.connectionLoading = false; // 로딩 끝
                        } else {
                            // 선택된 항목의 데이터와 보율을 인자로 전달
                            var is_success = serialManager.connectSerial(portComboBox.model[portComboBox.currentIndex].device, baudRateComboBox.currentValue);

                            connectSerialRoot.connectionStatusVisible = true;
                            connectSerialRoot.connectionStatusIsSuccess = is_success;
                            connectSerialRoot.connectionLoading = false; // 로딩 끝
                        }
                    }
                }
            }

            // 연결 상태 표시
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: connectSerialRoot.connectionStatusVisible

                Image {
                    source: connectSerialRoot.connectionStatusIsSuccess ? resourceManager.getUrl("assets/icons/serial/check_circle.svg") : resourceManager.getUrl("assets/icons/serial/block.svg")
                    sourceSize.width: 14
                    sourceSize.height: 14
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: connectSerialRoot.connectionStatusIsSuccess ? "Connection Successful" : "Connection Failed. Please Try Again."
                    color: connectSerialRoot.connectionStatusIsSuccess ? Colors.green : Colors.red
                    font.pixelSize: 14
                    font.weight: 500
                }
            }
        }
    }

    // 여백
    Item {
        Layout.fillHeight: true
    }

    // 포트 목록 업데이트 함수
    function updatePortList() {
        connectSerialRoot.portList = serialManager.getPortList() || [];
    }

    // 현재 선택된 포트와 보율을 가져오는 함수
    function getCurrentConnection() {
        var connection = serialManager.getCurrentConnection() || {};
        if (connection.port && connection.baudrate) {
            console.log("현재 연결된 포트:", connection.port);
            console.log("현재 연결된 보드레이트:", connection.baudrate);

            // 연결 상태 표시
            connectSerialRoot.connectionStatusVisible = true;
            connectSerialRoot.connectionStatusIsSuccess = true;

            // 연결된 포트와 보드레이트 설정
            portComboBox.currentIndex = connectSerialRoot.portList.findIndex(item => item.device === connection.port);
            baudRateComboBox.currentIndex = baudRateComboBox.model.findIndex(item => item === connection.baudrate);
        }
    }
}
