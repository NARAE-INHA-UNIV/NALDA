import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Colors 1.0

// Drone Status & Control Panel
Rectangle {
    id: root
    color: "#1a1a1a"
    
    // --- Internal Properties for Data Binding ---
    property bool connected: false
    property int lastHeartbeatTime: 0
    property bool isArmed: false
    property string flightMode: "Unknown"
    
    // Battery
    property int batteryRemaining: 0   // %
    property real batteryVoltage: 0.0  // V
    property real batteryCurrent: 0.0  // A
    
    // Motors (1000~2000 us) -> Normalized 0.0~1.0
    property var motorValues: [0, 0, 0, 0] 

    // --- Internal Properties for Data Binding ---
    property bool connected: false
    property int lastHeartbeatTime: 0
    property bool isArmed: false
    property int landedState: 0
    property string flightMode: "Unknown"

    property var stateList: [
        {
            id: 1,
            text: 'Disconnected',
            bgColor: Colors.gray800,
            borderColor: Colors.gray200
        },
        {
            id: 2,
            text: 'Disarmed',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 3,
            text: 'Armed',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
        {
            id: 4,
            text: 'In Air',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
        {
            id: 5,
            text: 'Takeoff',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
        {
            id: 6,
            text: 'Landing',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
        {
            id: 7,
            text: 'Connection Lost',
            bgColor: '#3e1b1b',
            borderColor: '#f44336'
        },
    ]
    property int stateId: 1

    property var modeList: [
        {
            id: 1,
            mode: 'MANUAL',
            text: 'Manual',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 2,
            mode: 'STABILIZED',
            text: 'Stabilized',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 3,
            mode: 'ACRO',
            text: 'Acro',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 4,
            mode: 'RATTITUDE',
            text: 'Rattitude',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 5,
            mode: 'ALTCTL',
            text: 'Altitude',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 6,
            mode: 'POSCTL',
            text: 'Position',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 7,
            mode: 'LOITER',
            text: 'Hold',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 8,
            mode: 'MISSION',
            text: 'Mission',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 9,
            mode: 'RTL',
            text: 'Return',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 10,
            mode: 'LAND',
            text: 'Land',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 11,
            mode: 'RTGS',
            text: 'Return',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 12,
            mode: 'FOLLOWME',
            text: 'Follow Me',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 13,
            mode: 'OFFBOARD',
            text: 'Offboard',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
        {
            id: 14,
            mode: 'TAKEOFF',
            text: 'Takeoff',
            bgColor: '#1b2a3e',
            borderColor: '#2196F3'
        },
    ]
    property int modeId: 13

    property var vtolStateList: [
        {
            id: 0,
            text: 'Undefined',
            bgColor: Colors.gray800,
            borderColor: Colors.gray400
        },
        {
            id: 1,
            text: 'Transition to FW',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 2,
            text: 'Transition to MC',
            bgColor: '#332b00',
            borderColor: '#ffc107'
        },
        {
            id: 3,
            text: 'Multicopter',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
        {
            id: 4,
            text: 'Fixed-Wing',
            bgColor: '#1b3e1b',
            borderColor: '#4caf50'
        },
    ]
    property int vtolStateId: 1

    // Battery
    property int batteryRemaining: 65   // %
    property real batteryVoltage: 22.4  // V
    property real batteryCurrent: 0.0  // A

    // Motors (1000~2000 us) -> Normalized 0.0~1.0
    property var motorValues: [1500, 1240, 1900, 1200]

    // Constants
    readonly property int timeoutMs: 3000

    // --- Connections to Backend ---
    Connections {
        target: serialManager

        function onMessageUpdated(msgId, msg) {
            // console.log("Received MAVLink Msg ID:", msgId);
            // Heartbeat (ID 0)
            if (msgId === 0) {
                root.connected = true;
                root.lastHeartbeatTime = new Date().getTime();

                var baseMode = msg.base_mode;
                root.isArmed = (baseMode & 128) !== 0;

                // For now, keep simple Connected/Armed display
                // If we get proper mode strings later, we can update this
                if (root.flightMode === "Unknown" || root.flightMode === "DISCONNECTED") {
                    root.flightMode = (baseMode & 128) ? "ARMED" : "DISARMED";
                } else {
                    root.flightMode = (baseMode & 128) ? "ARMED" : "DISARMED";
                }

                updateState();
            }

            // SYS_STATUS (ID 1)
            if (msgId === 1) {
                root.batteryVoltage = msg.voltage_battery / 1000.0;
                root.batteryCurrent = msg.current_battery / 100.0;

                // -1 means invalid/unknown in MAVLink, treat as 0 for graph
                var rem = msg.battery_remaining;
                if (rem < 0)
                    rem = 0;
                if (rem > 100)
                    rem = 100;
                root.batteryRemaining = rem;
            }

            // SERVO_OUTPUT_RAW (ID 36)
            if (msgId === 36) {
                var m1 = msg.servo1_raw;
                var m2 = msg.servo2_raw;
                var m3 = msg.servo3_raw;
                var m4 = msg.servo4_raw;
                root.motorValues = [m1, m2, m3, m4];
            }

            // EXTENDED_SYS_STATE (ID 245)
            if (msgId === 245) {
                root.vtolStateId = msg.vtol_state;
                root.landedState = msg.landed_state;
                updateState();
            }
        }
    }

    // --- Connection Timeout Logic ---
    // Timer {
    //     interval: 500
    //     running: true
    //     repeat: true
    //     onTriggered: {
    //         var currentTime = new Date().getTime();
    //         if (currentTime - root.lastHeartbeatTime > root.timeoutMs) {
    //             root.connected = false;
    //             root.batteryRemaining = 0;
    //             root.batteryVoltage = 0.0;
    //             root.motorValues = [0, 0, 0, 0];
    //             root.flightMode = "DISCONNECTED";
    //             root.isArmed = false;
    //             root.lastHeartbeatTime = currentTime;
    //             console.log("Connection timed out. Marking as disconnected.");
    //         }
    //     }
    // }

    // --- UI Layout ---
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 1. LEFT PANEL: Mode Selection (Vertical List)
        // Rectangle {
        //     Layout.fillHeight: true
        //     Layout.preferredWidth: 160
        //     color: "#222222"
        //     radius: 8

        //     ColumnLayout {
        //         anchors.fill: parent
        //         anchors.margins: 8
        //         spacing: 4

        //         // Header
        //         Rectangle {
        //             Layout.fillWidth: true
        //             Layout.preferredHeight: 30
        //             color: "transparent"
        //             Text {
        //                 anchors.centerIn: parent
        //                 text: "FLIGHT MODE"
        //                 color: "#808080"
        //                 font.pixelSize: 11
        //                 font.bold: true
        //             }
        //             Rectangle {
        //                 anchors.bottom: parent.bottom
        //                 width: parent.width
        //                 height: 1
        //                 color: "#333333"
        //             }
        //         }

        //         // Mode Buttons List
        //         ListView {
        //             Layout.fillWidth: true
        //             Layout.fillHeight: true
        //             clip: true
        //             model: ["Stabilized", "Acro", "Altitude", "Position", "Mission", "Hold", "Return", "Takeoff", "Land", "Offboard"]
        //             spacing: 4

        //             delegate: Button {
        //                 width: parent.width
        //                 height: 36
        //                 text: modelData

        //                 background: Rectangle {
        //                     color: parent.down ? "#FFB300" : "#2a2a2a"
        //                     radius: 4
        //                     border.color: parent.down ? "#FFB300" : "#333"
        //                     border.width: 1
        //                 }

        //                 contentItem: Text {
        //                     text: parent.text
        //                     color: parent.down ? "black" : "#e0e0e0"
        //                     font.pixelSize: 13
        //                     font.weight: Font.Medium
        //                     horizontalAlignment: Text.AlignHCenter
        //                     verticalAlignment: Text.AlignVCenter
        //                 }
        //             }
        //         }
        //     }
        // }

        // 2. RIGHT PANEL: Status & Monitoring
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#222222" // Grouping background
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // 2-1. Top Status Indicators
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    spacing: 15

                    // Flight Status Badge
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.stateList[root.stateId - 1].bgColor
                        // color: root.connected ? (root.isArmed ? "#1b3e20" : "#332b00") : "#3e1b1b"
                        radius: 6
                        border.color: root.stateList[root.stateId - 1].borderColor
                        // border.color: root.connected ? (root.isArmed ? "#4CAF50" : "#FFC107") : "#f44336"
                        border.width: 1

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            spacing: 4

                            Text {
                                text: "STATE"
                                color: "#808080"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: root.stateList[root.stateId - 1].text
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                    }

                    // Mode Badge
                    Rectangle {
                        id: modeBadge
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.modeList[root.modeId - 1].bgColor
                        radius: 6
                        border.color: root.modeList[root.modeId - 1].borderColor
                        border.width: 1

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            spacing: 4

                            Text {
                                text: "MODE"
                                color: "#808080"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: root.modeList[root.modeId - 1].text
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modeSelectionDialog.open();
                            }
                        }
                    }

                    // Mode Badge
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.vtolStateList[root.vtolStateId - 1].bgColor
                        radius: 6
                        border.color: root.vtolStateList[root.vtolStateId - 1].borderColor
                        border.width: 1

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            spacing: 4

                            Text {
                                text: "VTOL STATE"
                                color: "#808080"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: root.vtolStateList[root.vtolStateId - 1].text
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#333"
                }

                // 2-2. Monitoring Graphs (Motors & Battery)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 30

                    ColumnLayout {
                        Layout.preferredWidth: 120
                        Layout.fillHeight: true

                        Text {
                            text: "CONTROL"
                            color: "#808080"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Button {
                            Layout.fillWidth: true
                            height: 36
                            text: root.isArmed ? "Disarm" : "Arm"

                            onClicked: {
                                root.pendingCommand = text;
                                root.pendingCommandFunc = function () {
                                    serialManager.sendArmCommand(!root.isArmed);
                                };
                                commandConfirmDialog.open();
                            }

                            background: Rectangle {
                                color: parent.down ? "#FFB300" : (root.isArmed ? "#3e1b1b" : "#2a2a2a")
                                radius: 4
                                border.color: parent.down ? "#FFB300" : (root.isArmed ? "#f44336" : "#333")
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.down ? "black" : "#e0e0e0"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            height: 36
                            text: "Takeoff"

                            onClicked: {
                                root.pendingCommand = text;
                                root.pendingCommandFunc = function () {
                                    serialManager.sendTakeoffCommand(5.0);
                                };
                                commandConfirmDialog.open();
                            }

                            background: Rectangle {
                                color: parent.down ? "#FFB300" : "#2a2a2a"
                                radius: 4
                                border.color: parent.down ? "#FFB300" : "#333"
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.down ? "black" : "#e0e0e0"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            height: 36
                            text: "Land"

                            onClicked: {
                                root.pendingCommand = text;
                                root.pendingCommandFunc = function () {
                                    serialManager.sendLandCommand();
                                };
                                commandConfirmDialog.open();
                            }

                            background: Rectangle {
                                color: parent.down ? "#FFB300" : "#2a2a2a"
                                radius: 4
                                border.color: parent.down ? "#FFB300" : "#333"
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                color: parent.down ? "black" : "#e0e0e0"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Button {
                        //     Layout.fillWidth: true
                        //     height: 36
                        //     text: "Return"

                        //     onClicked: {
                        //         serialManager.sendReturnCommand();
                        //     }

                        //     background: Rectangle {
                        //         color: parent.down ? "#FFB300" : "#2a2a2a"
                        //         radius: 4
                        //         border.color: parent.down ? "#FFB300" : "#333"
                        //         border.width: 1
                        //     }

                        //     contentItem: Text {
                        //         text: parent.text
                        //         color: parent.down ? "black" : "#e0e0e0"
                        //         font.pixelSize: 13
                        //         font.weight: Font.Medium
                        //         horizontalAlignment: Text.AlignHCenter
                        //         verticalAlignment: Text.AlignVCenter
                        //     }
                        // }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // Vertical Divider
                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 20
                        Layout.bottomMargin: 20
                        color: "#333"
                    }

                    // Left Side: Motors
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            text: "MOTOR"
                            color: "#808080"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 12

                            Repeater {
                                model: 4
                                ColumnLayout {
                                    spacing: 6
                                    // Bar
                                    Rectangle {
                                        width: 28
                                        height: 140
                                        color: "#1a1a1a"
                                        radius: 3
                                        border.color: "#333"

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width - 4
                                            height: (parent.height - 4) * normalizeServo(root.motorValues[index])
                                            color: "#4CAF50"
                                            radius: 2
                                            anchors.margins: 2
                                        }
                                    }
                                    // Raw Value
                                    Text {
                                        // text: root.connected ? Math.round(root.motorValues[index]) : "----"
                                        text: Math.round(root.motorValues[index])
                                        color: "white"
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    // Motor Label
                                    Text {
                                        text: "M" + (index + 1)
                                        color: "#666666"
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    // Vertical Divider
                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 20
                        Layout.bottomMargin: 20
                        color: "#333"
                    }

                    // Right Side: Battery
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.rightMargin: 10

                        Text {
                            text: "BATTERY"
                            color: "#808080"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 6

                            // Bar
                            Rectangle {
                                width: 28
                                height: 140
                                color: "#1a1a1a"
                                radius: 3
                                border.color: "#333"

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 4
                                    height: (parent.height - 4) * (root.batteryRemaining / 100.0)
                                    color: root.batteryRemaining < 20 ? "#f44336" : "#4CAF50"
                                    radius: 2
                                    anchors.margins: 2
                                }
                            }
                            // Percentage Value
                            Text {
                                text: root.batteryRemaining + "%"
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            // Voltage Label
                            Text {
                                text: root.batteryVoltage.toFixed(1) + " V"
                                color: "#666666"
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }

    function updateState() {
        if (!root.connected) {
            root.stateId = 1; // Disconnected
            return;
        } else if (!root.isArmed) {
            root.stateId = 2; // Disarmed
            return;
        } else if (root.landedState === 1) {
            root.stateId = 3; // armed (on ground)
            return;
        } else if (root.landedState === 2) {
            root.stateId = 4; // in air
            return;
        } else if (root.landedState === 3) {
            root.stateId = 5; // taking off
            return;
        } else if (root.landedState === 4) {
            root.stateId = 6; // landing
            return;
        }
    }

    function normalizeServo(raw) {
        if (!raw)
            return 0.0;

        if (raw < 1000) {
            // 0 ~ 1000 범위는 그대로 0.0 ~ 1.0으로 매핑
            return raw / 1000.0;
        } else {
            // 1000 ~ 2000 범위는 0.0 ~ 1.0으로 매핑
            var val = (raw - 1000) / 1000.0;
            return Math.max(0.0, Math.min(1.0, val));
        }
    }

    // 선택된 모드를 임시 저장
    property string selectedMode: ""

    // 컨트롤 명령 확인용
    property string pendingCommand: ""
    property var pendingCommandFunc: null

    // 모드 선택 모달
    Dialog {
        id: modeSelectionDialog
        title: ""
        modal: true
        focus: true
        padding: 0
        topPadding: 0
        // bottomPadding: 0
        // leftPadding: 0
        // rightPadding: 0

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            color: Colors.gray900
            radius: 8
        }

        contentItem: Column {
            width: 220
            spacing: 0

            // Header
            Rectangle {
                width: parent.width
                // height: 50
                height: 15
                color: Colors.gray900
                radius: 8

                // Text {
                //     anchors.left: parent.left
                //     anchors.verticalCenter: parent.verticalCenter
                //     anchors.leftMargin: 15
                //     text: "Mode"
                //     color: "#e0e0e0"
                //     font.pixelSize: 18
                //     font.bold: true
                // }
            }

            // Content
            Rectangle {
                width: parent.width
                height: 200
                color: Colors.gray900

                ScrollView {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    GridLayout {
                        width: 190
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: root.modeList

                            Rectangle {
                                Layout.fillWidth: true
                                // Layout.preferredWidth: 85
                                Layout.preferredHeight: 35
                                color: root.selectedMode === modelData.mode ? Colors.green : "#2a2a2a"
                                radius: 6
                                border.color: root.selectedMode === modelData.mode ? Colors.green : "#3a3a3a"
                                border.width: root.selectedMode === modelData.mode ? 2 : 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: "#e0e0e0"
                                    font.pixelSize: 14
                                    font.weight: root.selectedMode === modelData.mode ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                    width: parent.width - 10
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onEntered: {
                                        if (root.selectedMode !== modelData.mode) {
                                            parent.color = "#333333";
                                        }
                                    }

                                    onExited: {
                                        if (root.selectedMode !== modelData.mode) {
                                            parent.color = "#2a2a2a";
                                        }
                                    }

                                    onClicked: {
                                        root.selectedMode = modelData.mode;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Rectangle {
                width: parent.width
                height: 60
                color: Colors.gray900
                radius: 8

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 15
                    spacing: 15

                    Button {
                        width: 100
                        height: 36
                        text: "Confirm"
                        enabled: root.selectedMode !== ""

                        onClicked: {
                            if (root.selectedMode !== "") {
                                serialManager.setFlightMode(root.selectedMode);
                                root.selectedMode = "";
                                modeSelectionDialog.close();
                            }
                        }

                        background: Rectangle {
                            color: parent.enabled ? Colors.green : "#555"
                            radius: 4
                            border.color: parent.enabled ? Colors.green : "#555"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? "white" : "#888"
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

    // 컨트롤 명령 확인 다이얼로그
    Dialog {
        id: commandConfirmDialog
        title: ""
        modal: true
        focus: true
        padding: 0
        topPadding: 0

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            color: Colors.gray900
            radius: 8
        }

        contentItem: Column {
            width: 250
            spacing: 0

            // Content
            Rectangle {
                width: parent.width
                height: 50
                color: Colors.gray900
                radius: 8

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.top: parent.top
                    anchors.topMargin: 18
                    text: root.pendingCommand + " 명령 실행하기"
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.weight: 500
                }
            }

            // Footer
            Rectangle {
                width: parent.width
                height: 62
                color: Colors.gray900
                radius: 8

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 15
                    spacing: 10

                    Button {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 46
                        text: "Cancel"

                        onClicked: {
                            commandConfirmDialog.close();
                        }

                        background: Rectangle {
                            color: parent.down ? "#555" : "#3a3a3a"
                            radius: 8
                            border.color: "#555"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#e0e0e0"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 46
                        text: "Confirm"

                        onClicked: {
                            if (root.pendingCommandFunc) {
                                root.pendingCommandFunc();
                            }
                            commandConfirmDialog.close();
                        }

                        background: Rectangle {
                            color: parent.down ? "#2e7d32" : Colors.green
                            radius: 8
                            border.color: Colors.green
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
                         Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
