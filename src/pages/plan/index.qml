import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15

Rectangle {
    id: initPage
    color: "#2a2a2a"
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.margins: 20

    property var waypoints: []

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        
        Item {
            width: parent.width
            height: childrenRect.height + 40
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
            
            // 첫 번째 ColumnLayout: 웨이포인트 입력 및 목록
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.5
                spacing: 20
                
                // Header
                Text {
                    text: "GPS waypoint 입력 및 천이 옵션 지정"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                }
            
            // 웨이포인트 입력 부분
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 340
                color: "#3a3a3a"
                radius: 10
                border.color: "#555555"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    Text {
                        text: "새 웨이포인트 추가"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 15
                    
                            // Waypoint name input
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "이름:"
                                    color: "white"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 80
                                }
                                
                                TextField {
                                    id: waypointNameField
                                    Layout.fillWidth: true
                                    placeholderText: "웨이포인트 이름을 입력하세요"
                                    color: "white"
                                    background: Rectangle {
                                        color: "#4a4a4a"
                                        border.color: "#666666"
                                        border.width: 1
                                        radius: 5
                                    }
                                }
                            }
                            
                            // Latitude input
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "위도:"
                                    color: "white"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 80
                                }
                                
                                TextField {
                                    id: latitudeField
                                    Layout.fillWidth: true
                                    placeholderText: "예: 37.5665"
                                    color: "white"
                                    validator: DoubleValidator {
                                        bottom: -90.0
                                        top: 90.0
                                        decimals: 8
                                    }
                                    background: Rectangle {
                                        color: "#4a4a4a"
                                        border.color: "#666666"
                                        border.width: 1
                                        radius: 5
                                    }
                                }
                                
                                Text {
                                    text: "°"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                            }
                            
                            // Longitude input
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "경도:"
                                    color: "white"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 80
                                }
                                
                                TextField {
                                    id: longitudeField
                                    Layout.fillWidth: true
                                    placeholderText: "예: 126.9780"
                                    color: "white"
                                    validator: DoubleValidator {
                                        bottom: -180.0
                                        top: 180.0
                                        decimals: 8
                                    }
                                    background: Rectangle {
                                        color: "#4a4a4a"
                                        border.color: "#666666"
                                        border.width: 1
                                        radius: 5
                                    }
                                }
                                
                                Text {
                                    text: "°"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                            }
                            
                            // Altitude input
                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "고도:"
                                    color: "white"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 80
                                }
                                
                                TextField {
                                    id: altitudeField
                                    Layout.fillWidth: true
                                    placeholderText: "예: 100 (미터)"
                                    color: "white"
                                    validator: DoubleValidator {
                                        bottom: -500.0
                                        top: 50000.0
                                        decimals: 2
                                    }
                                    background: Rectangle {
                                        color: "#4a4a4a"
                                        border.color: "#666666"
                                        border.width: 1
                                        radius: 5
                                    }
                                }
                                
                                Text {
                                    text: "m"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                    
                    // Add waypoint button
                    Button {
                        text: "웨이포인트 추가"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        
                        background: Rectangle {
                            color: parent.pressed ? "#4CAF50" : "#5CBF60"
                            radius: 6
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                        
                        onClicked: {
                            if (waypointNameField.text.trim() !== "" && 
                                latitudeField.text.trim() !== "" && 
                                longitudeField.text.trim() !== "") {
                                
                                var waypoint = {
                                    name: waypointNameField.text.trim(),
                                    latitude: parseFloat(latitudeField.text),
                                    longitude: parseFloat(longitudeField.text),
                                    altitude: altitudeField.text.trim() !== "" ? parseFloat(altitudeField.text) : 0
                                };
                                
                                waypoints.push(waypoint);
                                waypointListModel.append(waypoint);
                                
                                waypointNameField.text = "";
                                latitudeField.text = "";
                                longitudeField.text = "";
                                altitudeField.text = "";
                                
                                console.log("Added waypoint:", waypoint.name, waypoint.latitude, waypoint.longitude, waypoint.altitude);
                            } else {
                                console.log("Please fill in all required fields (name, latitude, longitude)");
                            }
                        }
                    }
                }
            }
            
            // 웨이포인트 목록
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 340
                color: "#3a3a3a"
                radius: 10
                border.color: "#555555"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15
                    
                    Text {
                        text: "웨이포인트 목록"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: ListModel {
                            id: waypointListModel
                        }
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 60
                            color: "#4a4a4a"
                            radius: 5
                            border.color: "#666666"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 15
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: model.name
                                        color: "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    
                                    Text {
                                        text: "위도: " + model.latitude.toFixed(6) + "°  경도: " + model.longitude.toFixed(6) + "°  고도: " + model.altitude + "m"
                                        color: "#cccccc"
                                        font.pixelSize: 12
                                    }
                                }
                                
                                Button {
                                    text: "삭제"
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 30
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#d32f2f" : "#f44336"
                                        radius: 4
                                    }
                                    
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.bold: true
                }
                                    
                                    onClicked: {
                                        waypoints.splice(index, 1);
                                        waypointListModel.remove(index);
                                    }
                                }
                            }
                        }
                    }
                    
                    // Clear all waypoints button
                    Button {
                        text: "모든 웨이포인트 삭제"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 10
                        
                        background: Rectangle {
                            color: parent.pressed ? "#d32f2f" : "#f44336"
                            radius: 6
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                        
                        onClicked: {
                            waypoints = [];
                            waypointListModel.clear();
                        }
                    }
                }
            }
            
            // 액션 
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                
                // TODO: 미션 시작 버튼 - FC팀 연동 후 활성화 예정
                // FC(Flight Control)팀으로부터 받을 .py 파일들:
                // - spline.py: 스플라인 곡선 기반 경로 생성
                // - cubic.py: 3차 곡선 기반 부드러운 경로 생성
                // - 기타 경로 생성 알고리즘들
                // 
                // 구현 예정 기능:
                // 1. FC팀 .py 파일을 통한 정밀한 경로점 생성
                // 2. 미션 업로드 및 실행 명령 전송
                // 3. 실시간 미션 상태 모니터링
                // 4. 미션 중단/재개/수정 기능
                /*
                Button {
                    text: "미션 시작"
                    Layout.preferredWidth: 150
                    
                    background: Rectangle {
                        color: parent.pressed ? "#1976D2" : "#2196F3"
                        radius: 6
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }
                    
                    onClicked: {
                        // FC팀 경로 생성 모듈 호출
                        // var pathGenerator = fcPathModule.createPath(waypoints, "spline")
                        // var optimizedPath = pathGenerator.generateOptimizedPath()
                        // 
                        // MAVLink 통신을 통한 미션 업로드
                        // mavlinkController.uploadMission(optimizedPath)
                        // mavlinkController.startMission()
                        
                        if (waypoints.length > 0) {
                            console.log("Starting mission with", waypoints.length, "waypoints");
                            for (var i = 0; i < waypoints.length; i++) {
                                console.log("Waypoint", i + 1, ":", waypoints[i].name, waypoints[i].latitude, waypoints[i].longitude, waypoints[i].altitude);
                            }
                        } else {
                            console.log("No waypoints to start mission");
                        }
                    }
                }
                */
            }
            }
            
            // 두 번째 ColumnLayout: 웨이포인트 지도
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.5
                
                // Map section
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 450
                    color: "#3a3a3a"
                    radius: 10
                    border.color: "#555555"
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15
                    
                    Text {
                        text: "웨이포인트 지도"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    // 지도 영역
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#000000"
                        radius: 6
                        
                        Map {
                            id: waypointMap
                            anchors.fill: parent
                            plugin: Plugin {
                                name: "osm"   // OpenStreetMap 무료 지도
                            }
                            center: QtPositioning.coordinate(37.450767, 126.657016) // 초기 위치: 인하대
                            zoomLevel: 15
                            
                            // 줌 레벨 제한
                            minimumZoomLevel: 1
                            maximumZoomLevel: 20
                            
                            // 드래그 기능 구현
                            MouseArea {
                                id: mapMouseArea
                                anchors.fill: parent
                                
                                property point startPoint
                                property var startCenter
                                
                                onPressed: function(mouse) {
                                    startPoint = Qt.point(mouse.x, mouse.y)
                                    startCenter = waypointMap.center
                                }
                                
                                onPositionChanged: function(mouse) {
                                    if (pressed) {
                                        var deltaX = mouse.x - startPoint.x
                                        var deltaY = mouse.y - startPoint.y
                                        
                                        // 화면 좌표 차이를 지리적 좌표 차이로 변환
                                        var startCoord = waypointMap.toCoordinate(startPoint)
                                        var currentCoord = waypointMap.toCoordinate(Qt.point(mouse.x, mouse.y))
                                        
                                        var newLat = startCenter.latitude - (currentCoord.latitude - startCoord.latitude)
                                        var newLng = startCenter.longitude - (currentCoord.longitude - startCoord.longitude)
                                        
                                        waypointMap.center = QtPositioning.coordinate(newLat, newLng)
                                    }
                                }
                            }
                            
                            // 마우스 휠 줌 기능
                            WheelHandler {
                                onWheel: {
                                    var delta = event.angleDelta.y / 120 // 표준 휠 스크롤 단위
                                    var newZoomLevel = waypointMap.zoomLevel + delta * 0.5
                                    
                                    // 줌 레벨 제한 검사
                                    if (newZoomLevel >= waypointMap.minimumZoomLevel && newZoomLevel <= waypointMap.maximumZoomLevel) {
                                        waypointMap.zoomLevel = newZoomLevel
                                    }
                                }
                            }
                            
                            // 웨이포인트들을 연결하는 경로선
                            MapPolyline {
                                id: waypointPath
                                line.color: "#2196F3" // 파란색 경로선
                                line.width: 3
                                path: {
                                    var pathCoordinates = [];
                                    for (var i = 0; i < waypoints.length; i++) {
                                        pathCoordinates.push(QtPositioning.coordinate(waypoints[i].latitude, waypoints[i].longitude));
                                    }
                                    return pathCoordinates;
                                }
                            }
                            
                            // 웨이포인트 마커들
                            MapItemView {
                                model: waypointListModel
                                delegate: MapQuickItem {
                                    coordinate: QtPositioning.coordinate(model.latitude, model.longitude)
                                    anchorPoint.x: 17
                                    anchorPoint.y: 17
                                    
                                    sourceItem: Rectangle {
                                        width: 34
                                        height: 34
                                        radius: 17
                                        color: "#FF9800" // 주황색 배경
                                        border.color: "white"
                                        border.width: 2
                                        
                                        // 그림자 효과
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width + 4
                                            height: parent.height + 4
                                            radius: (parent.width + 4) / 2
                                            color: "#00000040" // 반투명 검정
                                            z: -1
                                        }
                                        
                                        Text {
                                            anchors.centerIn: parent
text: model.name.substring(0, 3)
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 16
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 지도 컨트롤 버튼들
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10
                        
                        Button {
                            text: "전체 보기"
                            Layout.preferredWidth: 80
                            
                            background: Rectangle {
                                color: parent.pressed ? "#1976D2" : "#2196F3"
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                            }
                            
                            onClicked: {
                                if (waypoints.length > 0) {
                                    // 모든 웨이포인트가 보이도록 지도 범위 조정
                                    var minLat = waypoints[0].latitude;
                                    var maxLat = waypoints[0].latitude;
                                    var minLon = waypoints[0].longitude;
                                    var maxLon = waypoints[0].longitude;
                                    
                                    for (var i = 1; i < waypoints.length; i++) {
                                        minLat = Math.min(minLat, waypoints[i].latitude);
                                        maxLat = Math.max(maxLat, waypoints[i].latitude);
                                        minLon = Math.min(minLon, waypoints[i].longitude);
                                        maxLon = Math.max(maxLon, waypoints[i].longitude);
                                    }
                                    
                                    var centerLat = (minLat + maxLat) / 2;
                                    var centerLon = (minLon + maxLon) / 2;
                                    
                                    waypointMap.center = QtPositioning.coordinate(centerLat, centerLon);
                                    
                                    // 적절한 줌 레벨 계산
                                    var latDiff = maxLat - minLat;
                                    var lonDiff = maxLon - minLon;
                                    var maxDiff = Math.max(latDiff, lonDiff);
                                    
                                    if (maxDiff > 0.1) waypointMap.zoomLevel = 10;
                                    else if (maxDiff > 0.05) waypointMap.zoomLevel = 12;
                                    else if (maxDiff > 0.01) waypointMap.zoomLevel = 14;
                                    else waypointMap.zoomLevel = 16;
                                }
                            }
                        }
                        
                        Button {
                            text: "확대"
                            Layout.preferredWidth: 50
                            
                            background: Rectangle {
                                color: parent.pressed ? "#388E3C" : "#4CAF50"
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                            }
                            
                            onClicked: {
                                if (waypointMap.zoomLevel < 18) {
                                    waypointMap.zoomLevel += 1;
                                }
                            }
                        }
                        
                        Button {
                            text: "축소"
                            Layout.preferredWidth: 50
                            
                            background: Rectangle {
                                color: parent.pressed ? "#F57F17" : "#FFC107"
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                            }
                            
                            onClicked: {
                                if (waypointMap.zoomLevel > 1) {
                                    waypointMap.zoomLevel -= 1;
                                }
                            }
                        }
                    }
                }
            }
            }
            }
        }
    }
}