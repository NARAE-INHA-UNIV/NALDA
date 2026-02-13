import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtLocation 5.15
import QtPositioning 5.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: ndRoot
    color: "#1a1a1a"

    // gpsBackend의 시그널을 처리하기 위한 Connections
    Connections {
        target: gpsManager
        // gpsBackend가 유효한 경우에만 시그널 핸들러 활성화
        enabled: gpsManager !== null

        function onGpsDataChanged(lat, lon, alt, hdg) {
            // console.log("QML Received GPS:", lat, lon, alt, hdg);
            var newCoordinate = QtPositioning.coordinate(lat, lon);
            map.center = newCoordinate;
            // droneMarker의 coordinate는 pathData의 마지막 요소를 통해 자동으로 업데이트되므로 여기서 직접 설정할 필요가 없다.
            gpsInfoText.text = `[현재 위치]   위도: ${lat.toFixed(7)}   |   경도: ${lon.toFixed(7)}   |   방위각: ${hdg.toFixed(2)}°`;
        }

        // pathData가 변경되면 MapPolyline과 MapItemView가 자동으로 업데이트하므로, onPathDataChanged 핸들러는 명시적으로 필요하지 않다.
    }

    Rectangle {
        anchors.fill: parent
        color: "#2a2a2a"
        radius: 8

        Item {
            anchors.fill: parent

            // 지도
            Map {
                id: map
                anchors.fill: parent
                anchors.margins: 0
                layer.enabled: true
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: map.width
                        height: map.height
                        radius: 6
                    }
                }
                plugin: Plugin {
                    name: "osm"
                    PluginParameter {
                        name: "osm.useragent"
                        value: "NALDA"
                    }
                    PluginParameter {
                        name: "osm.mapping.providersrepository.disabled"
                        value: true
                    }
                    PluginParameter {
                        name: "osm.mapping.custom.host"
                        value: "https://tile.thunderforest.com/cycle/%z/%x/%y.png?apikey=" + gpsManager.getOSMApiKey()
                    }
                    // PluginParameter {
                    //     name: "osm.mapping.custom.datacopyright"
                    //     value: "© Thunderforest, © OpenStreetMap contributors"
                    // }
                }
                activeMapType: supportedMapTypes.length > 0 ? supportedMapTypes[supportedMapTypes.length - 1] : supportedMapTypes[0]
                center: QtPositioning.coordinate(37.450767, 126.657016) // 초기 위치: 인하대
                zoomLevel: 17

                // 줌 레벨 제한
                minimumZoomLevel: 1
                maximumZoomLevel: 20

                // 드래그 기능 구현
                MouseArea {
                    id: mapMouseArea
                    anchors.fill: parent

                    property point startPoint
                    property var startCenter

                    onPressed: function (mouse) {
                        startPoint = Qt.point(mouse.x, mouse.y);
                        startCenter = map.center;
                    }

                    onPositionChanged: function (mouse) {
                        if (pressed) {
                            var deltaX = mouse.x - startPoint.x;
                            var deltaY = mouse.y - startPoint.y;

                            // 화면 좌표 차이를 지리적 좌표 차이로 변환
                            var startCoord = map.toCoordinate(startPoint);
                            var currentCoord = map.toCoordinate(Qt.point(mouse.x, mouse.y));

                            var newLat = startCenter.latitude - (currentCoord.latitude - startCoord.latitude);
                            var newLng = startCenter.longitude - (currentCoord.longitude - startCoord.longitude);

                            map.center = QtPositioning.coordinate(newLat, newLng);
                        }
                    }
                }

                // 마우스 휠 줌 기능
                WheelHandler {
                    onWheel: function (event) {
                        var delta = event.angleDelta.y / 120; // 표준 휠 스크롤 단위
                        var newZoomLevel = map.zoomLevel + delta * 0.5;

                        // 줌 레벨 제한 검사
                        if (newZoomLevel >= map.minimumZoomLevel && newZoomLevel <= map.maximumZoomLevel) {
                            map.zoomLevel = newZoomLevel;
                        }
                    }
                }

                // 드론 이동 경로 (실선)
                MapPolyline {
                    path: gpsManager ? gpsManager.pathCoordinates : []
                    line.color: "#FF0000" // 빨간색
                    line.width: 3
                }

                // 과거 경로 지점들 (빨간 원 + 숫자)
                MapItemView {
                    // 현재 위치(마지막 점)를 제외한 모든 점을 모델로 사용
                    model: gpsManager ? gpsManager.pathCoordinates.slice(0, gpsManager.pathCoordinates.length - 1) : []
                    delegate: MapQuickItem {
                        coordinate: modelData
                        anchorPoint.x: 10
                        anchorPoint.y: 10
                        sourceItem: Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "red"
                            border.color: "white"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: index + 1 // 경로 순서 (1부터 시작)
                                color: "white"
                                font.bold: true
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                // 드론 현재 위치 마커 (초록 원 + 숫자)
                MapQuickItem {
                    id: droneMarker
                    anchorPoint.x: 15
                    anchorPoint.y: 15
                    // pathData가 비어있지 않으면 가장 마지막 좌표를 사용
                    coordinate: (gpsManager && gpsManager.pathCoordinates.length > 0) ? gpsManager.pathCoordinates[gpsManager.pathCoordinates.length - 1] : QtPositioning.coordinate(37.450767, 126.657016)

                    sourceItem: Rectangle {
                        width: 30
                        height: 30
                        color: "green" // 현재 위치는 초록색
                        radius: 15
                        border.color: "white"
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: gpsManager ? gpsManager.pathCoordinates.length : 0 // 경로 순서
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }
                }
            }

            // GPS 정보 표시 텍스트
            Text {
                id: gpsInfoText
                anchors.centerIn: parent
                text: "GPS 정보 수신 기다리는 중..."
                color: "black"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 10

                text: "경로 기록 조회"
                onClicked: {
                    gpsManager.showLocationHistory();
                }
            }
        }
    }
}
