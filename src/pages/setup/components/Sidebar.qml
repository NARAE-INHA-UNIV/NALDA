import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15


Rectangle {
    id: sidebar
    color: "#2a2a2a"

    signal pageSelected(string pageName)
    
    property var menuItems: [
        { id: 1, name: "보드 연결" },
        { id: 2, name: "센서값 시각화" },
        { id: 3, name: "자세 시각화" },
    ]
    property int selectedPageId: 1
    

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Repeater {
            id: menuRepeater
            model: sidebar.menuItems

            delegate: Rectangle {
                id: menuItem
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignHCenter
                radius: 8
                color: sidebar.selectedPageId === menuItem.modelData.id ? "#3a3a3a" : "#2a2a2a"

                function updateColor() {
                    if (sidebar.selectedPageId === menuItem.modelData.id) {
                        color = "#3a3a3a"
                    } else {
                        color = "#2a2a2a"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onClicked: {
                        sidebar.selectedPageId = menuItem.modelData.id
                        sidebar.pageSelected(menuItem.modelData.id)
                        
                        // 모든 메뉴 아이템의 색상을 강제로 업데이트
                        for (let i = 0; i < menuRepeater.count; i++) {
                            menuRepeater.itemAt(i).updateColor()
                        }
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