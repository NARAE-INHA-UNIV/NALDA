
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15


// 왼쪽 패널 - 드론 상태 및 컨트롤
Rectangle {
    color: "#1a1a1a"

    // 샘플 데이터
    // property var tableData: [
    //     { id: 1, latitude: "N37.5665", longitude: "E126.9780", mode: "회전익",},
    //     { id: 2, latitude: "N37.5665", longitude: "E126.9780", mode: "천이",},
    //     { id: 3, latitude: "N37.5665", longitude: "E126.9780", mode: "고정익",},
    // ]
        
    Rectangle {
        anchors.fill: parent
        color: "#2a2a2a"
        radius: 8

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            // 제목
            Text {
                text: "드론 상태"
                font.pixelSize: 20
                font.weight: 700
                color: "white"
                Layout.bottomMargin: 15
            }
            
            GridLayout {
                // Layout.margins: 15
                columns: 2
                rows: 3
                columnSpacing: 10
                rowSpacing: 10
                
                // 배터리1 상태
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: "배터리1"
                            color: "#999999"
                            font.pixelSize: 14
                            font.weight: 500
                        }
                        
                        ProgressBar {
                            Layout.fillWidth: true
                            value: 0.75
                            Material.accent: Material.Green
                        }
                        
                        Text {
                            text: "75%"
                            color: "#e4e4e4"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
                
                // 배터리2 상태
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: "배터리2"
                            color: "#999999"
                            font.pixelSize: 14
                            font.weight: 500
                        }
                        
                        ProgressBar {
                            Layout.fillWidth: true
                            value: 0.80
                            Material.accent: Material.Green
                        }
                        
                        Text {
                            text: "80%"
                            color: "#e4e4e4"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
                
                // 비행 시간
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        Text {
                            text: "비행 시간"
                            color: "#999999"
                            font.pixelSize: 14
                            font.weight: 500
                        }
                        
                        Text {
                            text: "05:23"
                            color: "white"
                            font.pixelSize: 24
                            font.weight: 700  // bold 대신 수치 사용 (100~900)
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // 속도 정보
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: "속도"
                            color: "#999999"
                            font.pixelSize: 14
                        }
                        
                        Text {
                            text: "15 m/s"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // 비행 거리
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: "비행 거리"
                            color: "#999999"
                            font.pixelSize: 14
                            font.weight: 500
                        }
                        
                        Text {
                            text: "542 m"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                // 고도 정보
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    color: "#3a3a3a"
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Text {
                            text: "고도"
                            color: "#999999"
                            font.pixelSize: 14
                            font.weight: 500
                        }
                        
                        Text {
                            text: "120 m"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
                
                
            }

            Item { Layout.fillHeight: true }
        }
    }
}

// 오른쪽 패널 - 컨트롤 및 설정
// Rectangle {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     color: "#2a2a2a"
//     radius: 8

//     ColumnLayout {
//         anchors.fill: parent
//         anchors.margins: 20

//         // 제목
//         Text {
//             text: "컨트롤 패널"
//             font.pixelSize: 20
//             font.weight: 700
//             color: "white"
//             Layout.bottomMargin: 15
//         }

//         RowLayout {
//             Layout.fillWidth: true
//             spacing: 20

//             Rectangle {
//                 Layout.fillHeight: true
//                 width: 250

//                 color: "#2a2a2a"

//                 ColumnLayout {
//                     anchors.fill: parent

//                     // 비행모드 선택
//                     RowLayout {
//                         Layout.fillWidth: true
//                         spacing: 8
//                         Text {
//                             text: "비행모드"
//                             color: "white"
//                             font.pixelSize: 16
//                         }
//                         ComboBox {
//                             Layout.fillWidth: true
//                             Layout.preferredHeight: 40
//                             model: ["자동", "수동"]
//                             currentIndex: 0
//                         }
//                     }

//                     Button {
//                         text: "이륙"
//                         Layout.fillWidth: true
//                         background: Rectangle { color: "#4CAF50"; radius: 8 }
//                         contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 14; font.weight: 700; horizontalAlignment: Text.AlignHCenter }
//                     }
//                     Button {
//                         text: "복귀"
//                         Layout.fillWidth: true
//                         background: Rectangle { color: "#FF9800"; radius: 8 }
//                         contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 14; font.weight: 700; horizontalAlignment: Text.AlignHCenter }
//                     }
//                     Button {
//                         text: "착륙"
//                         Layout.fillWidth: true
//                         background: Rectangle { color: "#FF9800"; radius: 8 }
//                         contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 14; font.weight: 700; horizontalAlignment: Text.AlignHCenter }
//                     }

//                     Item { Layout.fillHeight: true }
//                 }
//             }

//             Rectangle {
//                 Layout.fillWidth: true
//                 Layout.fillHeight: true
//                 color: "#2a2a2a"

//                 ColumnLayout {
//                     anchors.fill: parent

//                     // 현재 목표 waypoint
//                     Rectangle {
//                         Layout.fillWidth: true
//                         Layout.bottomMargin: 10
//                         height: 50
//                         color: "#333"
//                         radius: 8
//                         RowLayout {
//                             anchors.fill: parent
//                             anchors.margins: 10
//                             spacing: 8
//                             Text {
//                                 text: "Current Waypoint"
//                                 color: "white"
//                                 font.pixelSize: 14
//                                 font.weight: 600
//                             }
//                             Text {
//                                 text: "N37.5665, E126.9780"
//                                 color: "#4CAF50"
//                                 font.pixelSize: 16
//                                 font.weight: 700
//                             }
//                         }
//                     }

//                     // 비행계획 (GPS waypoint)
//                     Rectangle {
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                         border.color: "#606060"
//                         border.width: 1
//                         radius: 8
//                         color: "#2a2a2a"

                        
//                         ColumnLayout {
//                             anchors.fill: parent
//                             anchors.margins: 1
//                             spacing: 0
                            
//                             // 테이블 헤더
//                             Rectangle {
//                                 Layout.fillWidth: true
//                                 Layout.preferredHeight: 40
//                                 color: "#2a2a2a"
//                                 topLeftRadius: 8
//                                 topRightRadius: 8
                                
//                                 Rectangle {
//                                     anchors.bottom: parent.bottom
//                                     width: parent.width
//                                     height: 1
//                                     color: "#606060"
//                                 }
                                
                                
//                                 RowLayout {
//                                     anchors.fill: parent
//                                     anchors.leftMargin: 15
//                                     anchors.rightMargin: 15
//                                     spacing: 0
                                    
//                                     Text {
//                                         text: "No"
//                                         font.pixelSize: 14
//                                         font.bold: true
//                                         color: "white"
//                                         Layout.preferredWidth: 100
//                                     }
                                    
//                                     Text {
//                                         text: "위도"
//                                         font.pixelSize: 14
//                                         font.bold: true
//                                         color: "white"
//                                         Layout.preferredWidth: 150
//                                     }
                                    
//                                     Text {
//                                         text: "경도"
//                                         font.pixelSize: 14
//                                         font.bold: true
//                                         color: "white"
//                                         Layout.preferredWidth: 150
//                                     }
                                    
//                                     Text {
//                                         text: "모드"
//                                         font.pixelSize: 14
//                                         font.bold: true
//                                         color: "white"
//                                         Layout.fillWidth: true
//                                     }
//                                 }
//                             }

                            
//                             // 테이블 내용
//                             Rectangle {
//                                 Layout.fillWidth: true
//                                 Layout.fillHeight: true
//                                 color: "#2a2a2a"
//                                 radius: 8
//                                 clip: true

//                                 ScrollView {
//                                     anchors.fill: parent
                                    
//                                     ListView {
//                                         id: tableListView
//                                         model: mainPanelPage.tableData
                                        
//                                         delegate: Rectangle {
//                                             id: tableRow
//                                             required property int index
//                                             required property var modelData
                                            
//                                             width: tableListView.width
//                                             height: 40
//                                             color: "#2a2a2a"
                                            
//                                             MouseArea {
//                                                 anchors.fill: parent
//                                                 hoverEnabled: true
//                                                 onEntered: tableRow.color = "#3a3a3a"
//                                                 onExited: tableRow.color = "#2a2a2a"
//                                             }
                                            
//                                             RowLayout {
//                                                 anchors.fill: parent
//                                                 anchors.leftMargin: 5
//                                                 anchors.rightMargin: 5
//                                                 spacing: 0
                                                
//                                                 Text {
//                                                     text: tableRow.modelData.id
//                                                     font.pixelSize: 14
//                                                     color: "white"
//                                                     Layout.preferredWidth: 100
//                                                     elide: Text.ElideRight
//                                                     Layout.leftMargin: 10
//                                                 }
                                                
//                                                 Text {
//                                                     text: tableRow.modelData.latitude
//                                                     font.pixelSize: 14
//                                                     color: "white"
//                                                     Layout.preferredWidth: 150
//                                                     elide: Text.ElideRight
//                                                 }
                                                
//                                                 Text {
//                                                     text: tableRow.modelData.longitude
//                                                     font.pixelSize: 14
//                                                     color: "white"
//                                                     Layout.preferredWidth: 150
//                                                     elide: Text.ElideRight
//                                                 }
                                                
//                                                 Text {
//                                                     text: tableRow.modelData.mode
//                                                     font.pixelSize: 14
//                                                     color: "white"
//                                                     Layout.fillWidth: true
//                                                     elide: Text.ElideRight
//                                                 }
//                                             }
                                            
//                                             Rectangle {
//                                                 anchors.bottom: parent.bottom
//                                                 width: parent.width
//                                                 height: 1
//                                                 color: "#606060"
//                                                 visible: tableRow.index !== tableListView.count - 1
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }