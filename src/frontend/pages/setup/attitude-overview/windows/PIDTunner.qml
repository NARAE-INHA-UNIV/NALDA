import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Colors 1.0

Rectangle {
    id: pidControlSection
    width: 600
    height: 480
    color: Colors.backgroundSecondary

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // 섹션 제목
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "PID Gain Tunner"
                color: Colors.textPrimary
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            // Always on top 버튼
            Button {
                id: alwaysOnTopButton
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                property bool isAlwaysOnTop: false

                contentItem: Image {
                    source: resourceManager.getUrl("assets/icons/map/satellite_alt.svg")
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 20
                    sourceSize.height: 20
                }

                background: Rectangle {
                    color: alwaysOnTopButton.isAlwaysOnTop ? Colors.primary : (alwaysOnTopButton.hovered ? "#555555" : "transparent")
                    radius: 6
                    border.color: alwaysOnTopButton.hovered ? Colors.primary : "transparent"
                    border.width: 1
                }

                onClicked: {
                    isAlwaysOnTop = !isAlwaysOnTop;
                    // 백엔드로 always on top 상태 전송
                    attitudeOverviewManager.setAlwaysOnTop(isAlwaysOnTop);
                }
            }
        }

        // 설명 텍스트
        Text {
            text: "각도 제어(상단)와 각속도 제어(하단) 이득을 설정하세요."
            color: Colors.gray100
            font.pixelSize: 16
        }

        // PID 테이블 그리드
        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            columns: 4
            rowSpacing: 10
            columnSpacing: 15

            // 헤더 행 (빈 셀 + P, I, D 라벨)
            Item {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 30
            }

            Text {
                text: "P"
                color: Colors.textPrimary
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 120
            }

            Text {
                text: "I"
                color: Colors.textPrimary
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 120
            }

            Text {
                text: "D"
                color: Colors.textPrimary
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 120
            }

            // 각도 제어 (angle) - Roll
            Text {
                text: "Roll 각도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: rollAngleP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: "#333333"
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: rollAngleI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: "#333333"
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: rollAngleD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            // 각도 제어 (angle) - Pitch
            Text {
                text: "Pitch 각도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: pitchAngleP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: pitchAngleI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: pitchAngleD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            // 각도 제어 (angle) - Yaw
            Text {
                text: "Yaw 각도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: yawAngleP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: yawAngleI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: yawAngleD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            // 구분선 (빈 공간)
            Rectangle {
                Layout.columnSpan: 4
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#444444"
            }

            // 각속도 제어 (rate) - Roll
            Text {
                text: "Roll 각속도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: rollRateP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: rollRateI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: rollRateD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            // 각속도 제어 (rate) - Pitch
            Text {
                text: "Pitch 각속도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: pitchRateP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: pitchRateI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: pitchRateD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            // 각속도 제어 (rate) - Yaw
            Text {
                text: "Yaw 각속도"
                color: Colors.textPrimary
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            TextField {
                id: yawRateP
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: yawRateI
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }

            TextField {
                id: yawRateD
                text: "0.0"
                color: Colors.textPrimary
                background: Rectangle {
                    color: Colors.backgroundTertiary
                    radius: 4
                }
                selectByMouse: true
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                horizontalAlignment: TextInput.AlignHCenter
                validator: DoubleValidator {
                    bottom: 0.0
                    decimals: 6
                }
            }
        }

        // 전송 버튼
        Button {
            id: sendPidButton
            text: "PID 설정값 전송"
            Layout.topMargin: 20
            Layout.preferredWidth: 180
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignRight

            contentItem: Text {
                text: sendPidButton.text
                font.pixelSize: 14
                color: Colors.white
                font.weight: 600
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: sendPidButton.pressed ? Qt.darker(Colors.primary, 1.2) : Colors.primary
                radius: 8
            }

            onClicked: {
                // PID 값을 수집하여 객체로 구성
                var pidValues = {
                    angle: {
                        roll: {
                            p: parseFloat(rollAngleP.text),
                            i: parseFloat(rollAngleI.text),
                            d: parseFloat(rollAngleD.text)
                        },
                        pitch: {
                            p: parseFloat(pitchAngleP.text),
                            i: parseFloat(pitchAngleI.text),
                            d: parseFloat(pitchAngleD.text)
                        },
                        yaw: {
                            p: parseFloat(yawAngleP.text),
                            i: parseFloat(yawAngleI.text),
                            d: parseFloat(yawAngleD.text)
                        }
                    },
                    rate: {
                        roll: {
                            p: parseFloat(rollRateP.text),
                            i: parseFloat(rollRateI.text),
                            d: parseFloat(rollRateD.text)
                        },
                        pitch: {
                            p: parseFloat(pitchRateP.text),
                            i: parseFloat(pitchRateI.text),
                            d: parseFloat(pitchRateD.text)
                        },
                        yaw: {
                            p: parseFloat(yawRateP.text),
                            i: parseFloat(yawRateI.text),
                            d: parseFloat(yawRateD.text)
                        }
                    }
                };

                // 백엔드로 PID 값 전송 (attitudeOverviewManager를 통해)
                // attitudeOverviewManager.sendPidValues(pidValues);
                console.log("PID 값 전송:", JSON.stringify(pidValues));
            }
        }
    }
}
