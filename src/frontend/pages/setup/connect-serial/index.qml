import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import Styles 1.0

ColumnLayout {
    id: connectSerialRoot
    anchors.fill: parent

    property string connectionMode: "serial" // "serial" or "udp"
    property string boardType: "custom" // "custom" or "px4"
    property bool isConnected: false
    property bool connectionStatusVisible: false
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

        // 연결 모드 선택
        Rectangle {
            color: Colors.gray700
            Layout.preferredWidth: 300
            Layout.preferredHeight: 40
            radius: 8

            RowLayout {
                spacing: 4
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5

                Button {
                    id: serialModeButton
                    text: "Serial"
                    Layout.preferredWidth: 143
                    Layout.fillHeight: true
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                    contentItem: Text {
                        text: serialModeButton.text
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: connectSerialRoot.connectionMode === "serial" ? Colors.gray800 : "transparent"
                        radius: 6
                    }

                    onClicked: {
                        connectSerialRoot.connectionMode = "serial";
                    }
                }

                Button {
                    id: udpModeButton
                    text: "UDP"
                    Layout.preferredWidth: 143
                    Layout.fillHeight: true
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                    contentItem: Text {
                        text: udpModeButton.text
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: connectSerialRoot.connectionMode === "udp" ? Colors.gray800 : "transparent"
                        radius: 6
                    }

                    onClicked: {
                        connectSerialRoot.connectionMode = "udp";
                    }
                }
            }
        }

        // Serial 연결 UI
        ColumnLayout {
            visible: connectSerialRoot.connectionMode === "serial"
            Layout.fillWidth: true
            spacing: 20
            Layout.topMargin: 20

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Layout.bottomMargin: -8

                Text {
                    text: "Board"
                    color: Colors.gray100
                    font.pixelSize: 14
                    font.bold: true
                }

                RowLayout {

                    RadioButton {
                        id: customFCRadio
                        text: "자작 FC"
                        checked: connectSerialRoot.boardType === "custom"
                        Layout.preferredWidth: 150
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                        indicator: Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            border.width: 2
                            border.color: Colors.gray400
                            color: "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                anchors.centerIn: parent
                                color: Colors.gray400
                                visible: customFCRadio.checked
                            }
                        }

                        contentItem: Text {
                            text: customFCRadio.text
                            color: Colors.textPrimary
                            font.pixelSize: 14
                            leftPadding: customFCRadio.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            connectSerialRoot.boardType = "custom";
                        }
                    }

                    RadioButton {
                        id: px4Radio
                        text: "PX4"
                        checked: connectSerialRoot.boardType === "px4"
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                        indicator: Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            border.width: 2
                            border.color: Colors.gray400
                            color: "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                anchors.centerIn: parent
                                color: Colors.gray400
                                visible: px4Radio.checked
                            }
                        }

                        contentItem: Text {
                            text: px4Radio.text
                            color: Colors.textPrimary
                            font.pixelSize: 14
                            leftPadding: px4Radio.indicator.width + 8
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            connectSerialRoot.boardType = "px4";
                        }
                    }
                }
            }

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
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                        background: Rectangle {
                            color: Colors.gray800
                            radius: 4
                            border.width: 1
                            border.color: portComboBoxMouseArea.containsMouse ? Colors.gray100 : Colors.gray400
                        }

                        MouseArea {
                            id: portComboBoxMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onPressed: mouse.accepted = false
                        }

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
                                    color: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading) ? Colors.textPrimary : Colors.gray100
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
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

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
                    enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)

                    background: Rectangle {
                        color: Colors.gray800
                        radius: 4
                        border.width: 1
                        border.color: baudRateMouseArea.containsMouse ? Colors.gray100 : Colors.gray400
                    }

                    MouseArea {
                        id: baudRateMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onPressed: mouse.accepted = false
                    }

                    contentItem: Text {
                        text: baudRateComboBox.currentValue
                        color: baudRateComboBox.enabled ? Colors.textPrimary : Colors.gray400
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 12
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 40

                        contentItem: Text {
                            text: modelData
                            color: Colors.textPrimary
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: parent.hovered ? Colors.gray500 : "transparent"
                        }
                    }
                }
            }
        }

        // UDP 연결 UI
        ColumnLayout {
            visible: connectSerialRoot.connectionMode === "udp"
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 20

            // IP 입력
            ColumnLayout {
                spacing: 8

                Text {
                    text: "IP Address"
                    color: Colors.gray100
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 40
                    color: Colors.gray800
                    radius: 4
                    border.color: ipTextInput.activeFocus ? Colors.gray100 : Colors.gray400

                    TextInput {
                        id: ipTextInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        text: "127.0.0.1"
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)
                    }
                }
            }

            // Port 입력
            ColumnLayout {
                spacing: 8

                Text {
                    text: "Port"
                    color: Colors.gray100
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 40
                    color: Colors.gray800
                    radius: 4
                    border.color: udpPortTextInput.activeFocus ? Colors.gray100 : Colors.gray400

                    TextInput {
                        id: udpPortTextInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        text: "14550"
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        enabled: !(connectSerialRoot.isConnected || connectSerialRoot.connectionLoading)
                        validator: IntValidator {
                            bottom: 0
                            top: 65535
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: 30

            Button {
                id: connectButton
                Layout.preferredHeight: 50
                Layout.preferredWidth: 300
                text: connectSerialRoot.connectionLoading ? (connectSerialRoot.isConnected ? "연결 해제 중..." : "연결 중...") : (connectSerialRoot.isConnected ? "연결 해제하기" : "연결하기")
                enabled: !connectSerialRoot.connectionLoading // 연결 중일 때 비활성화
                background: Rectangle {
                    color: connectButton.enabled ? (connectSerialRoot.isConnected ? (mouseArea.containsMouse ? Qt.darker(Colors.red, 1.05) : Colors.red) : (mouseArea.containsMouse ? Qt.darker(Colors.green, 1.05) : Colors.green)) : Colors.gray600
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
                        if (connectSerialRoot.connectionMode === "serial") {
                            if (portComboBox.currentIndex === -1) {
                                console.log("포트를 선택해주세요.");
                                return;
                            }
                        } else if (connectSerialRoot.connectionMode === "udp") {
                            if (ipTextInput.text === "") {
                                console.log("IP 주소를 입력해주세요.");
                                return;
                            }
                            if (udpPortTextInput.text === "") {
                                console.log("Port를 입력해주세요.");
                                return;
                            }
                        }

                        // 버튼을 연결 중 상태로 변경
                        connectSerialRoot.connectionLoading = true;
                        connectSerialRoot.connectionStatusVisible = false;

                        // 0.5초 후에 연결 함수 실행
                        // UI 업데이트 시간을 확보하기 위함
                        connectionTimer.start();
                    }
                }

                Timer {
                    id: connectionTimer
                    interval: 500
                    running: false
                    repeat: false
                    onTriggered: {
                        if (connectSerialRoot.isConnected) {
                            // 연결 해제
                            if (connectSerialRoot.connectionMode === "serial") {
                                // Serial 연결 해제
                                connectSerialRoot.isConnected = !serialManager.disconnectSerial();
                            } else if (connectSerialRoot.connectionMode === "udp") {
                                // UDP 연결 해제
                                connectSerialRoot.isConnected = !serialManager.disconnectUDP();
                            }
                            connectSerialRoot.connectionLoading = false; // 로딩 끝
                        } else {
                            // 연결
                            if (connectSerialRoot.connectionMode === "serial") {
                                // Serial 연결
                                var is_px4 = connectSerialRoot.boardType === "px4";
                                var device = portComboBox.model[portComboBox.currentIndex].device;
                                var baudrate = baudRateComboBox.currentValue;
                                connectSerialRoot.isConnected = serialManager.connectSerial(is_px4, device, baudrate);
                            } else if (connectSerialRoot.connectionMode === "udp") {
                                // UDP 연결
                                var udp_ip = ipTextInput.text;
                                var udp_port = parseInt(udpPortTextInput.text);
                                connectSerialRoot.isConnected = serialManager.connectUDP(udp_ip, udp_port);
                            }

                            connectSerialRoot.connectionStatusVisible = true;
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
                    source: connectSerialRoot.isConnected ? resourceManager.getUrl("assets/icons/serial/check_circle.svg") : resourceManager.getUrl("assets/icons/serial/block.svg")
                    sourceSize.width: 14
                    sourceSize.height: 14
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: connectSerialRoot.isConnected ? "Connection Successful" : "Connection Failed. Please Try Again."
                    color: connectSerialRoot.isConnected ? Colors.green : Colors.red
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
        if (connection.is_serial && connection.port && connection.baudrate) {
            // 연결 상태 표시
            connectSerialRoot.connectionStatusVisible = true;
            connectSerialRoot.isConnected = true;

            // 연결된 보드, 포트, 보드레이트 설정
            connectSerialRoot.boardType = connection.is_px4 ? "px4" : "custom";
            portComboBox.currentIndex = connectSerialRoot.portList.findIndex(item => item.device === connection.port);
            baudRateComboBox.currentIndex = baudRateComboBox.model.findIndex(item => item === connection.baudrate);
        }
        if (!connection.is_serial && connection.udp_ip && connection.udp_port) {
            // 연결 상태 표시
            connectSerialRoot.connectionStatusVisible = true;
            connectSerialRoot.isConnected = true;

            // 연결된 UDP IP와 Port 설정
            ipTextInput.text = connection.udp_ip;
            udpPortTextInput.text = connection.udp_port.toString();
        }
    }
}
