import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15

import "./components" as Components

Rectangle {
    id: mainWindow
    anchors.fill: parent
    color: "#1a1a1a"

    // Material 테마 설정
    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // 페이지 목록을 한 곳에서 관리
    property var pageMap: [
        {
            name: "SETUP",
            source: "pages/setup/index.qml",
            icon: "assets/icons/sidebar/usb.svg"
        },
        {
            name: "PLAN",
            source: "pages/plan/index.qml",
            icon: "assets/icons/sidebar/map.svg"
        },
        {
            name: "FLIGHT",
            source: "pages/flight/index.qml",
            icon: "assets/icons/sidebar/flight.svg"
        }
        // {
        //     name: "CONFIG",
        //     source: "pages/config/index.qml",
        //     icon: "assets/icons/sidebar/settings.svg"
        // },
        ,
    ]
    property string currentPage: "FLIGHT"

    // 메인 레이아웃
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 왼쪽 사이드바
        Components.Sidebar {
            Layout.fillHeight: true
            Layout.preferredWidth: 60

            // 사이드바 목록을 사이드바에 전달
            menuItems: mainWindow.pageMap

            // 사이드바에서 선택된 페이지를 메인 윈도우에 전달
            onPageSelected: function (pageName) {
                mainWindow.currentPage = pageName;
            }
        }

        // 메인 컨텐츠 영역
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20

            Loader {
                id: pageLoader
                anchors.fill: parent

                source: mainWindow.pageMap.find(item => item.name === mainWindow.currentPage).source
            }
        }
    }
}
