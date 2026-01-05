import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtWebEngine 1.10
import Styles 1.0

ColumnLayout {
    id: attitudeOverviewRoot
    anchors.fill: parent

    property var messageFrame: []
    property int selectedMessageId: 30

    property bool htmlLoaded: false

    property real rollAngle: 0
    property real pitchAngle: 0
    property real yawAngle: 0

    property bool showFixedAxes: true
    property bool showHelperAxes: true

    // htmlLoaded 변경 감지 핸들러 추가
    // 30번 ATTITUDE를 받아오도록 수정
    onHtmlLoadedChanged: {
        if (htmlLoaded) {
            var metaData = attitudeOverviewManager.setTargetMessage(attitudeOverviewRoot.selectedMessageId);

            // 단위를 rad에서 degree로 변환
            for (var i = 0; i < metaData.fields.length; i++) {
                if (metaData.fields[i].units === "rad") {
                    metaData.fields[i].units = "degree";
                }
                if (metaData.fields[i].units === "rad/s") {
                    metaData.fields[i].units = "degree/s";
                }
            }

            attitudeOverviewRoot.messageFrame = metaData.fields;

            var jsCode = `window.receiveGraphMetaData(${JSON.stringify(metaData.fields)});`;
            webView.runJavaScript(jsCode);
        }
    }

    // 메시지 업데이트 수신용 Connection
    Connections {
        target: attitudeOverviewManager

        function onMessageUpdated(data) {
            // 자세 업데이트
            // 30번 ATTITUDE 값은 rad 이므로 변환
            data.roll = data.roll * 180 / 3.14592;
            data.pitch = data.pitch * 180 / 3.14592;
            data.yaw = data.yaw * 180 / 3.14592;

            // 3D 모델 자세 업데이트
            attitudeOverviewRoot.rollAngle = data.roll;
            attitudeOverviewRoot.pitchAngle = data.pitch;
            attitudeOverviewRoot.yawAngle = data.yaw;

            // HTML이 완전히 로드된 경우에만 JavaScript 함수 호출
            if (attitudeOverviewRoot.htmlLoaded) {
                var jsCode = `window.receiveData(${JSON.stringify(data)});`;
                webView.runJavaScript(jsCode);
            } else {
                console.log("HTML이 아직 로드되지 않았습니다. 데이터 무시:");
            }
        }
    }

    // 상단 제목
    Text {
        text: "자세 시각화"
        color: Colors.textPrimary
        font.pixelSize: 24
        font.bold: true
    }

    ColumnLayout {
        Layout.topMargin: 20
        Layout.fillWidth: true
        Layout.fillHeight: true

        // 컨텐츠 영역 - 직접 구현한 스크롤
        // ScrollView, Flickable을 사용하면 마우스 드래그 이벤트를 가로채서 3D 모
        Rectangle {
            id: customScrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            clip: true

            property real contentY: 0
            property real contentHeight: columnContent.height

            // 스크롤을 위한 MouseArea
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                onWheel: function (wheel) {
                    var delta = wheel.angleDelta.y;
                    var newContentY = parent.contentY - delta / 3;

                    // 경계값 체크
                    var maxContentY = Math.max(0, parent.contentHeight - parent.height);
                    parent.contentY = Math.max(0, Math.min(maxContentY, newContentY));

                    wheel.accepted = true;
                }
            }

            ColumnLayout {
                id: columnContent
                width: parent.width
                y: -parent.contentY // 스크롤 오프셋 적용

                // 3D 모델 영역
                ModelContainer {
                    id: modelContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400

                    rollAngle: attitudeOverviewRoot.rollAngle
                    pitchAngle: attitudeOverviewRoot.pitchAngle
                    yawAngle: attitudeOverviewRoot.yawAngle

                    showFixedAxes: attitudeOverviewRoot.showFixedAxes
                    showHelperAxes: attitudeOverviewRoot.showHelperAxes
                }

                // 체크박스 영역
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    spacing: 20

                    // 우측 정렬을 위한 여백
                    Item {
                        Layout.fillWidth: true
                    }

                    CheckBox {
                        id: fixedCoordinateCheckBox
                        text: "고정좌표계 표시"
                        checked: true
                        Material.accent: Colors.green

                        contentItem: Text {
                            text: fixedCoordinateCheckBox.text
                            color: Colors.textPrimary
                            font.pixelSize: 14
                            leftPadding: fixedCoordinateCheckBox.indicator.width + fixedCoordinateCheckBox.spacing
                            verticalAlignment: Text.AlignVCenter
                        }

                        onCheckedChanged: {
                            attitudeOverviewRoot.showFixedAxes = checked;
                        }
                    }

                    CheckBox {
                        id: auxiliaryCoordinateCheckBox
                        text: "보조좌표계 표시"
                        checked: true
                        Material.accent: Colors.green

                        contentItem: Text {
                            text: auxiliaryCoordinateCheckBox.text
                            color: Colors.textPrimary
                            font.pixelSize: 14
                            leftPadding: auxiliaryCoordinateCheckBox.indicator.width + auxiliaryCoordinateCheckBox.spacing
                            verticalAlignment: Text.AlignVCenter
                        }

                        onCheckedChanged: {
                            attitudeOverviewRoot.showHelperAxes = checked;
                        }
                    }
                }

                // 그래프 영역
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 450 * 2 // 그래프 개수
                    Layout.topMargin: 30

                    WebEngineView {
                        id: webView
                        anchors.fill: parent
                        url: Qt.resolvedUrl("../../../components/uplot/stream-data.html")
                        // url: "src:/pages/setup/attitude-overview/uplot/stream-data.html"

                        onLoadingChanged: function (loadRequest) {
                            if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                                console.log("Failed to load:", loadRequest.errorString);
                                attitudeOverviewRoot.htmlLoaded = false;
                            } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                                console.log("Successfully loaded HTML file");
                                attitudeOverviewRoot.htmlLoaded = true;
                            }
                        }

                        onJavaScriptConsoleMessage: function (level, message, lineNumber, sourceID) {
                            console.log("JS Console:", message);
                        }
                    }

                    // 마우스 휠 이벤트를 스크롤로 전달
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton

                        onWheel: function (wheel) {
                            var delta = wheel.angleDelta.y;
                            var newContentY = customScrollArea.contentY - delta / 3;

                            // 경계값 체크
                            var maxContentY = Math.max(0, customScrollArea.contentHeight - customScrollArea.height);
                            customScrollArea.contentY = Math.max(0, Math.min(maxContentY, newContentY));

                            wheel.accepted = true;
                        }
                    }
                }

                // PID 제어 이득 설정
                // 임시 설정. 추후 다른 메뉴로 개편 예정
                Item {
                    id: pidControlSection
                    Layout.fillWidth: true
                    Layout.preferredHeight: 480
                    Layout.topMargin: 30

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        // 섹션 제목
                        Text {
                            text: "PID 제어 이득 설정"
                            color: Colors.textPrimary
                            font.pixelSize: 20
                            font.bold: true
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
                                attitudeOverviewManager.sendPidValues(pidValues);
                                // console.log("PID 값 전송:", JSON.stringify(pidValues));
                            }
                        }
                    }
                }
            }
        }
    }
}
