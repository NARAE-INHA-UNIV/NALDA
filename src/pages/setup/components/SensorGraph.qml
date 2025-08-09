import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtWebEngine 1.10

ColumnLayout {
    id: sensorGraphRoot
    anchors.fill: parent


    property var messageList: [
        { id: 26, name: "SCALED_IMU" },
        
    ]
    property int selectedMessageId: 1

    property string selectedMessageName: ""
    property string selectedMessageDesc: ""
    property var messageFrame: [
        { name: "time_boot_ms", units: "ms", type: "uint32_t", plot: true },
        { name: "xacc", units: "mG", type: "int16_t", plot: true },
        { name: "yacc", units: "mG", type: "int16_t", plot: true },
        { name: "zacc", units: "mG", type: "int16_t", plot: true },
        { name: "xgyro", units: "mrad/s", type: "int16_t", plot: true },
        { name: "ygyro", units: "mrad/s", type: "int16_t", plot: true },
        { name: "zgyro", units: "mrad/s", type: "int16_t", plot: true },
        { name: "xmag", units: "mgauss", type: "int16_t", plot: true },
        { name: "ymag", units: "mgauss", type: "int16_t", plot: true },
        { name: "zmag", units: "mgauss", type: "int16_t", plot: true },
        { name: "temperature", units: "cdegC", type: "int16_t", plot: true }
    ]

    // 일부러 messageFrame과 분리
    // 지속적인 업데이트를 하다보니 plot의 checkbox가 흔들림
    property var selectedMessageValues: []

    // htmlLoaded 변경 감지 핸들러 추가
    // 처음에 첫 번째 메시지 선택해서 출력
    property bool htmlLoaded: false
    onHtmlLoadedChanged: {
        if (htmlLoaded && sensorGraphRoot.messageList.length > 0) {
            sensorGraphRoot.selectedMessageId = sensorGraphRoot.messageList[0].id
            initializePortSelect.set_target_message(sensorGraphRoot.selectedMessageId)
            console.log("자동으로 첫 번째 메시지 선택:", sensorGraphRoot.selectedMessageId)
        }
    }

    // messageList 초기화
    Component.onCompleted: {
        sensorGraphRoot.messageList = initializePortSelect.get_message_list() || []
    }

    // 메시지 메타데이터 수신용 Connection
    Connections {
        target: initializePortSelect

        function onMessageMetaDataReady(jsonData) {
            var metaData = JSON.parse(jsonData)
            sensorGraphRoot.selectedMessageName = metaData.name
            sensorGraphRoot.selectedMessageDesc = metaData.description
            sensorGraphRoot.messageFrame = metaData.fields

            if (sensorGraphRoot.htmlLoaded) {
                var jsCode = "window.receiveGraphMetaData(" + JSON.stringify(metaData.fields) + ");"
                webView.runJavaScript(jsCode)
            } else {
                console.log("HTML이 아직 로드되지 않았습니다. 데이터 무시:")
            }
        }
    }

    // 메시지 업데이트 수신용 Connection
    Connections {
        target: initializePortSelect

        function onMessageUpdated(data) {
            console.log("메시지 업데이트 수신:", data)

            // table의 value 업데이트
            sensorGraphRoot.selectedMessageValues = data;

            // HTML이 완전히 로드된 경우에만 JavaScript 함수 호출
            if (sensorGraphRoot.htmlLoaded) {
                var jsCode = "window.receiveData(" + JSON.stringify(data) + ");"
                webView.runJavaScript(jsCode)
            } else {
                console.log("HTML이 아직 로드되지 않았습니다. 데이터 무시:")
            }
        }
    }


    // 상단 제목
    Text {
        text: "센서값 시각화"
        color: "#dddddd"
        font.pixelSize: 24
        font.bold: true
    }

    // 컨텐츠 영역
    RowLayout {
        Layout.topMargin: 20
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Repeater {
                id: menuRepeater
                model: sensorGraphRoot.messageList

                delegate: Rectangle {
                    id: menuItem
                    required property var modelData

                    Layout.preferredWidth: 250
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignHCenter
                    radius: 8
                    color: sensorGraphRoot.selectedMessageId === menuItem.modelData.id ? "#33803F" : "#3a3a3a"

                    function updateColor() {
                        if (sensorGraphRoot.selectedMessageId === menuItem.modelData.id) {
                            color = "#33803F"
                        } else {
                            color = "#3a3a3a"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onClicked: handleClick()

                        function handleClick() {
                            sensorGraphRoot.selectedMessageId = menuItem.modelData.id
                            console.log("메시지 ID 변경:", sensorGraphRoot.selectedMessageId)
                            
                            // 시그널 방식으로 메타데이터 요청
                            initializePortSelect.set_target_message(sensorGraphRoot.selectedMessageId)
                            
                            // 모든 메뉴 아이템의 색상을 강제로 업데이트
                            for (let i = 0; i < menuRepeater.count; i++) {
                                menuRepeater.itemAt(i).updateColor()
                            }
                        }
                    }

                    Text {
                        text: modelData.id + " : " + modelData.name
                        color: "#dddddd"
                        font.pixelSize: 16
                        font.weight: 500
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    
                }
            }

            // 여백
            Item { Layout.fillHeight: true }
        }

        Flickable {
            id: mainFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            contentWidth: width
            contentHeight: mainColumn.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: mainColumn
                width: parent.width
                
                // 선택된 메시지의 제목
                Text {
                    text: sensorGraphRoot.selectedMessageName
                    color: "#dddddd"
                    font.pixelSize: 24
                    font.weight: 600
                    Layout.fillWidth: true
                }

                // 선택된 메시지의 설명
                Text {
                    text: sensorGraphRoot.selectedMessageDesc
                    color: "#dddddd"
                    font.pixelSize: 16
                    font.weight: 500
                    Layout.fillWidth: true
                    Layout.maximumWidth: parent.width
                    wrapMode: Text.Wrap
                }
                
                // 테이블 뷰
                ListView {
                    id: tableView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35 * (sensorGraphRoot.messageFrame.length + 1) // 헤더 + 행들
                    Layout.topMargin: 20
                    model: sensorGraphRoot.messageFrame
                    clip: true
                    interactive: false
                    
                    header: Rectangle {
                        width: parent.width
                        height: 35
                        color: "#3a3a3a"
                        
                        Row {
                            anchors.fill: parent
                            spacing: 0
                            
                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: "name"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: "value"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: "units"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: "type"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }
                            
                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: "plot"
                                    color: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }
                        }
                    }
                    
                    delegate: Rectangle {
                        id: tableRow
                        required property int index
                        required property var modelData
                        
                        width: parent.width
                        height: 35
                        color: index % 2 === 0 ? "#2a2a2a" : "#333333"
                        
                        Row {
                            anchors.fill: parent
                            spacing: 0
                            
                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: tableRow.modelData.name
                                    color: "#dddddd"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: sensorGraphRoot.selectedMessageValues[tableRow.index].toString()
                                    color: "#dddddd"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                            }
                            
                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: tableRow.modelData.units
                                    color: "#dddddd"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                Text {
                                    text: tableRow.modelData.type
                                    color: "#dddddd"
                                    font.pixelSize: 12
                                    anchors.centerIn: parent
                                }
                            }
                            
                            Rectangle {
                                width: parent.width * 0.20
                                height: parent.height
                                color: "transparent"
                                border.color: "#555555"
                                border.width: 1
                                
                                CheckBox {
                                    id: plot1CheckBox
                                    anchors.centerIn: parent
                                    checked: tableRow.modelData.plot
                                    Material.accent: "#33803F"
                                    visible: !tableRow.modelData.name.startsWith("time") 

                                    onCheckedChanged: {
                                        sensorGraphRoot.messageFrame[tableRow.index].plot = checked

                                        if (sensorGraphRoot.htmlLoaded) {
                                            var jsCode = "window.receiveGraphMetaData(" + JSON.stringify(sensorGraphRoot.messageFrame) + ");"
                                            webView.runJavaScript(jsCode)
                                        } else {
                                            console.log("HTML이 아직 로드되지 않았습니다. 데이터 무시:")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 그래프
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 450 * (new Set(sensorGraphRoot.messageFrame.slice(1).map(f => f.units)).size) // 그래프 개수
                    Layout.topMargin: 30
                    
                    WebEngineView {
                        id: webView
                        anchors.fill: parent
                        url: Qt.resolvedUrl("uplot/stream-data.html")
                        
                        onLoadingChanged: function(loadRequest) {
                            if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                                console.log("Failed to load:", loadRequest.errorString)
                                sensorGraphRoot.htmlLoaded = false
                            } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                                console.log("Successfully loaded HTML file")
                                sensorGraphRoot.htmlLoaded = true
                            }
                        }

                        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
                            console.log("JS Console:", message)
                        }
                    }
                    
                    // 웹엔진뷰 위의 마우스 영역
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: false  // 호버 이벤트를 웹엔진뷰로 전달
                        
                        onWheel: function(wheel) {
                            var delta = wheel.angleDelta.y * 0.5  // 스크롤 속도 조정
                            var newY = mainFlickable.contentY - delta
                            var maxY = Math.max(0, mainFlickable.contentHeight - mainFlickable.height)
                            mainFlickable.contentY = Math.max(0, Math.min(maxY, newY))
                            wheel.accepted = true
                        }
                    }
                }

                // 여백
                Item { Layout.fillHeight: true }
            }
        }
    }
}