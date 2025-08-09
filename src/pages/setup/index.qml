import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

import "./components" as Components


Rectangle {
    id: setupComponent
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: "#1a1a1a"

    property var menuItems: [
        { id: 1, name: "보드 연결", source: "components/ConnectSerial.qml" },
        { id: 2, name: "센서값 시각화", source: "components/SensorGraph.qml" },
        { id: 3, name: "자세 시각화", source: "components/AttitudeOverview.qml" },
    ]
    property int selectedPageId: 1


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
            Components.Sidebar {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                Layout.margins: 20
                color: "#2a2a2a"

                onPageSelected: (pageId) => {
                    setupComponent.selectedPageId = pageId;
                }
            }

            // 컨텐츠 영역
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#2a2a2a"
                radius: 8

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    anchors.margins: 20
                    
                    source: setupComponent.menuItems.find(item => item.id === setupComponent.selectedPageId)?.source || "components/ConnectSerial.qml"
                }

            }
        }
    }
}