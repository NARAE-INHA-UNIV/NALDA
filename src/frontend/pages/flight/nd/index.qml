import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtLocation 5.15
import QtPositioning 5.15
import Colors 1.0

Rectangle {
    id: ndRoot
    color: Colors.backgroundPrimary

    property int satellitesVisibleNum: 0
    property real hdop: 0.0

    property real droneLatitude: 37.450767
    property real droneLongitude: 126.657016
    property real droneAltitude: 0.0
    property real droneHeading: 0.0

    property bool isInitialCenterSet: false

    // gpsBackend의 시그널을 처리하기 위한 Connections
    Connections {
        target: gpsManager

        function onGpsStatusChanged(satellitesVisible, hdop) {
            ndRoot.satellitesVisibleNum = satellitesVisible;
            ndRoot.hdop = hdop;
        }

        function onGpsCoordinateChanged(lat, lon, alt, hdg) {
            // console.log("GPS 좌표 변경: 위도=" + lat + ", 경도=" + lon + ", 고도=" + alt + ", 방위각=" + hdg);
            ndRoot.droneLatitude = lat;
            ndRoot.droneLongitude = lon;
            ndRoot.droneAltitude = alt;
            ndRoot.droneHeading = hdg;

            // 제일 처음에만 지도 중심을 드론 위치로 설정
            if (!isInitialCenterSet) {
                map.center = QtPositioning.coordinate(lat, lon);
                isInitialCenterSet = true;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.backgroundSecondary
        radius: 8

        OsmMap {
            id: map
            anchors.fill: parent
            anchors.margins: 0

            // 드론 현재 위치 마커
            MapQuickItem {
                id: droneMarker
                coordinate: QtPositioning.coordinate(ndRoot.droneLatitude, ndRoot.droneLongitude)
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2

                sourceItem: Item {
                    width: 40
                    height: 40

                    Image {
                        id: arrowImage
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: resourceManager.getUrl("assets/icons/map/current_marker.png")
                        fillMode: Image.PreserveAspectFit
                        rotation: ndRoot.droneHeading
                        smooth: true

                        // 이미지가 없을 경우 기본 화살표 표시
                        visible: status === Image.Ready
                    }
                }
            }
        }

        // GPS 연결 상태 표시
        Rectangle {
            id: gpsStatusIndicator
            width: 130
            height: 34
            radius: 34
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            border.color: Colors.gray100
            border.width: 1
            color: Colors.gray800

            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: resourceManager.getUrl("assets/icons/map/satellite_alt.svg")
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        text: satellitesVisibleNum.toString()
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "HDOP"
                        color: Colors.textPrimary
                        font.weight: 600
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: hdop.toFixed(1)
                        color: Colors.textPrimary
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
