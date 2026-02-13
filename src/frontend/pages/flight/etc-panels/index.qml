import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

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

    // Constants
    readonly property int timeoutMs: 3000

    // --- Connections to Backend ---
    Connections {
        target: serialManager
        
        function onMessageUpdated(msgId, msg) {
            // Heartbeat (ID 0)
            if (msgId === 0) {
                root.connected = true
                root.lastHeartbeatTime = new Date().getTime()
                
                var baseMode = msg.base_mode
                root.isArmed = (baseMode & 128) !== 0
                
                // For now, keep simple Connected/Armed display
                // If we get proper mode strings later, we can update this
                if (root.flightMode === "Unknown" || root.flightMode === "DISCONNECTED") {
                     root.flightMode = (baseMode & 128) ? "ARMED" : "DISARMED"
                } else {
                     root.flightMode = (baseMode & 128) ? "ARMED" : "DISARMED"
                }
            }
            
            // SYS_STATUS (ID 1)
            if (msgId === 1) {
                root.batteryVoltage = msg.voltage_battery / 1000.0
                root.batteryCurrent = msg.current_battery / 100.0
                
                // -1 means invalid/unknown in MAVLink, treat as 0 for graph
                var rem = msg.battery_remaining
                if (rem < 0) rem = 0
                if (rem > 100) rem = 100
                root.batteryRemaining = rem
            }
            
            // SERVO_OUTPUT_RAW (ID 36)
            if (msgId === 36) {
                var m1 = normalizeServo(msg.servo1_raw)
                var m2 = normalizeServo(msg.servo2_raw)
                var m3 = normalizeServo(msg.servo3_raw)
                var m4 = normalizeServo(msg.servo4_raw)
                root.motorValues = [m1, m2, m3, m4]
            }
        }
    }
    
    function normalizeServo(raw) {
        if (!raw) return 0.0;
        var val = (raw - 1000) / 1000.0;
        return Math.max(0.0, Math.min(1.0, val));
    }

    // --- Connection Timeout Logic ---
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            var currentTime = new Date().getTime()
            if (currentTime - root.lastHeartbeatTime > root.timeoutMs) {
                root.connected = false
                root.batteryRemaining = 0
                root.batteryVoltage = 0.0
                root.motorValues = [0, 0, 0, 0]
                root.flightMode = "DISCONNECTED"
                root.isArmed = false
            }
        }
    }

    // --- UI Layout ---
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 1. LEFT PANEL: Mode Selection (Vertical List)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 160
            color: "#222222"
            radius: 8
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "FLIGHT MODE"
                        color: "#808080"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: "#333333"
                    }
                }

                // Mode Buttons List
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ["Stabilized", "Acro", "Altitude", "Position", "Mission", "Hold", "Return", "Takeoff", "Land", "Offboard"]
                    spacing: 4
                    
                    delegate: Button {
                        width: parent.width
                        height: 36
                        text: modelData
                        
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
                }
            }
        }

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
                        color: root.connected ? (root.isArmed ? "#1b3e20" : "#332b00") : "#3e1b1b"
                        radius: 6
                        border.color: root.connected ? (root.isArmed ? "#4CAF50" : "#FFC107") : "#f44336"
                        border.width: 1
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: parent.parent.border.color
                                Text {
                                    anchors.centerIn: parent
                                    text: "Q"
                                    color: "black"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                            }
                            
                            Text {
                                text: root.connected ? (root.isArmed ? "ARMED" : "DISARMED") : "NO LINK"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                    }

                    // Mode Badge
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#333333"
                        radius: 6
                        border.color: "#444"
                        border.width: 1
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 10
                            
                            Text {
                                text: "M"
                                color: "#808080"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                text: root.flightMode
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.maximumWidth: 150
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

                    // Left Side: Motors
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Text {
                            text: "MOTOR OUTPUT"
                            color: "#808080"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Item { Layout.fillHeight: true } 

                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 12
                            
                            Repeater {
                                model: 4
                                ColumnLayout {
                                    spacing: 8
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
                                            height: (parent.height - 4) * root.motorValues[index]
                                            color: root.connected ? "#8BC34A" : "#333"
                                            radius: 2
                                            anchors.margins: 2
                                        }
                                        
                                        // Grid lines
                                        Column {
                                            anchors.fill: parent
                                            spacing: parent.height / 10
                                            Repeater {
                                                model: 9
                                                Rectangle {
                                                    width: parent.width
                                                    height: 1
                                                    color: "#000000"
                                                    opacity: 0.2
                                                }
                                            }
                                        }
                                    }
                                    // Value
                                    Text {
                                        text: root.connected ? Math.round(root.motorValues[index] * 100) : "--"
                                        color: "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                         Item { Layout.fillHeight: true } 
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
                        Layout.preferredWidth: 100
                        Layout.fillHeight: true
                        
                         Text {
                            text: "BATTERY"
                            color: "#00BCD4"
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item { Layout.fillHeight: true }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 4
                            
                            Text {
                                text: root.connected ? root.batteryRemaining + "%" : "--%"
                                color: root.batteryRemaining < 20 ? "#f44336" : "white"
                                font.pixelSize: 24
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: root.connected ? root.batteryVoltage.toFixed(1) + " V" : "-- V"
                                color: "#aaaaaa"
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignCenter
                            width: 50
                            height: 100
                            color: "#1a1a1a"
                            border.color: "#00BCD4"
                            radius: 3
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 3
                                height: (parent.height - 6) * (root.batteryRemaining / 100.0)
                                color: root.batteryRemaining < 20 ? "#f44336" : "#00BCD4"
                                radius: 1
                            }
                        }
                         Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}