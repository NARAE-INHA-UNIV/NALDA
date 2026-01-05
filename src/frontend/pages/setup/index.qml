import QtQuick 2.15
import QtQuick.Layouts 1.15
import Styles 1.0

Rectangle {
    id: setupPage
    color: Colors.backgroundSecondary
    radius: 8

    property var menuItems: [
        {
            id: 1,
            name: "보드 연결",
            source: "connect-serial/index.qml"
        },
        {
            id: 2,
            name: "센서값 시각화",
            source: "sensor-graph/index.qml"
        },
        {
            id: 3,
            name: "자세 시각화",
            source: "attitude-overview/index.qml"
        },
        {
            id: 4,
            name: "파라미터 설정",
            source: "parameter-setting/index.qml"
        }
    ]
    property int selectedMenuId: 1

    RowLayout {
        anchors.fill: parent

        // 설정 메뉴 목록
        Sidebar {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            Layout.margins: 20

            // 메뉴 목록을 사이드바에 전달
            menuItems: setupPage.menuItems

            // 사이드바에서 선택된 페이지를 업데이트
            onMenuSelected: menuId => {
                setupPage.selectedMenuId = menuId;
            }
        }

        // 컨텐츠 영역
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20

            Loader {
                id: pageLoader
                anchors.fill: parent

                source: setupPage.menuItems.find(item => item.id === setupPage.selectedMenuId).source
            }
        }
    }
}
