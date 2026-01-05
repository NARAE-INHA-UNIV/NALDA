import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15
import QtQuick.Dialogs
import Styles 1.0

Rectangle {
    id: planPage
    color: Colors.backgroundSecondary
    radius: 8

    property var waypoints: []
    // 알고리즘 목록 (사용자가 동적으로 추가/삭제 가능)
    property var algorithmOptions: []
    property string currentAlgorithm: ""

    // 알고리즘별 파일 데이터 저장소
    property var algorithmData: ({})

    // 현재 표시되는 경로 점들 (적용 버튼으로 선택되는 알고리즘의 경로)
    property var currentPathPoints: []

    // 알고리즘 목록 모델
    property ListModel algorithmListModel: ListModel {
        id: algorithmListModel
        Component.onCompleted: {
            // 기본 알고리즘들을 모델에 추가
            for (var i = 0; i < algorithmOptions.length; i++) {
                append({
                    "name": algorithmOptions[i]
                });
            }
        }
    }

    // 선택된 알고리즘의 저장된 데이터를 사용하여 경로 점들을 지도에 표시
    function loadPathFromFile(algo) {
        console.log("Loading path from stored data for algorithm:", algo);

        // 저장된 알고리즘 데이터 확인
        if (algorithmData[algo] && algorithmData[algo].waypoints) {
            console.log("Found stored data for", algo, "with", algorithmData[algo].waypoints.length, "path points");

            // 경로 점들을 currentPathPoints에 저장 (웨이포인트 목록에 추가하지 않음)
            currentPathPoints = [];
            var storedWaypoints = algorithmData[algo].waypoints;
            for (var i = 0; i < storedWaypoints.length; i++) {
                var pathPoint = {
                    name: storedWaypoints[i].name,
                    latitude: storedWaypoints[i].latitude,
                    longitude: storedWaypoints[i].longitude,
                    altitude: storedWaypoints[i].altitude
                };
                currentPathPoints.push(pathPoint);
            }

            console.log("Successfully loaded", currentPathPoints.length, "path points from stored", algo, "data");
            console.log("Path points will be displayed on map as separate markers");
            console.log("First path point:", currentPathPoints[0]);
            console.log("Last path point:", currentPathPoints[currentPathPoints.length - 1]);

            // 지도 업데이트를 위해 신호 발생
            pathPointsChanged();
        } else {
            console.log("No stored data found for algorithm:", algo);
            console.log("Available algorithms:", Object.keys(algorithmData));

            // 경로 점 초기화
            currentPathPoints = [];
            pathPointsChanged();

            // 폴백: 기존 방식으로 .txt 파일 읽기 시도
            var xhr = new XMLHttpRequest();
            xhr.open("GET", Qt.resolvedUrl(algo + ".txt"));
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 0 || xhr.status === 200) {
                        var lines = xhr.responseText.trim().split(/\r?\n/);
                        currentPathPoints = [];

                        for (var i = 0; i < lines.length; i++) {
                            var parts = lines[i].trim().split(/[ ,]+/);
                            if (parts.length >= 3) {
                                var pathPoint = {
                                    name: algo + "_" + (i + 1),
                                    latitude: parseFloat(parts[0]),
                                    longitude: parseFloat(parts[1]),
                                    altitude: parseFloat(parts[2])
                                };
                                currentPathPoints.push(pathPoint);
                            }
                        }
                        console.log("Fallback: Loaded", currentPathPoints.length, "path points from", algo, "file");
                        pathPointsChanged();
                    } else {
                        console.log("Failed to load path file for", algo, "status", xhr.status);
                    }
                }
            };
            xhr.send();
        }
    }

    // 경로 점 업데이트 신호
    signal pathPointsChanged

    // 업로드된 파일에서 직접 좌표를 파싱하여 경로 점으로 변환 (웨이포인트 목록에는 추가하지 않음)
    function parseCoordinatesFromText(text, algorithmName) {
        console.log("Parsing coordinates from uploaded file:", algorithmName);

        var pathPoints = [];  // 경로 점들만 저장
        var lines = text.trim().split(/\r?\n/);
        var coordinateCount = 0;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();

            // 빈 줄이나 주석 건너뛰기
            if (line === "" || line.startsWith("//") || line.startsWith("#") || line.startsWith("=")) {
                continue;
            }

            // 좌표 패턴 찾기: 위도, 경도 형태
            var coordinateMatch = line.match(/(\d+\.\d+)[,\s]+(\d+\.\d+)/);
            if (coordinateMatch) {
                var latitude = parseFloat(coordinateMatch[1]);
                var longitude = parseFloat(coordinateMatch[2]);

                // 유효한 GPS 좌표인지 확인
                if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) {
                    coordinateCount++;
                    var pathPoint = {
                        name: algorithmName + "_" + coordinateCount,
                        latitude: latitude,
                        longitude: longitude,
                        altitude: 10.0  // 기본 고도
                    };
                    pathPoints.push(pathPoint);
                }
            } else
            // 이미 변환된 형태: 위도 경도 고도
            {
                var parts = line.split(/[\s,]+/);
                if (parts.length >= 2) {
                    var lat = parseFloat(parts[0]);
                    var lon = parseFloat(parts[1]);
                    var alt = parts.length >= 3 ? parseFloat(parts[2]) : 10.0;

                    if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
                        coordinateCount++;
                        var pathPoint = {
                            name: algorithmName + "_" + coordinateCount,
                            latitude: lat,
                            longitude: lon,
                            altitude: alt
                        };
                        pathPoints.push(pathPoint);
                    }
                }
            }
        }

        console.log("Parsed", coordinateCount, "coordinates from", algorithmName);
        return pathPoints;  // 경로 점들 반환
    }

    // 업로드된 파일을 읽고 좌표를 파싱하는 함수
    function loadAndParseUploadedFile(algorithmName, fileUrl) {
        console.log("Loading uploaded file:", algorithmName, fileUrl);

        var xhr = new XMLHttpRequest();
        xhr.open("GET", fileUrl);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 0 || xhr.status === 200) {
                    // 알고리즘 데이터 저장
                    algorithmData[algorithmName] = {
                        fileUrl: fileUrl,
                        rawData: xhr.responseText,
                        waypoints: []
                    };

                    var pathPoints = parseCoordinatesFromText(xhr.responseText, algorithmName);
                    if (pathPoints && pathPoints.length > 0) {
                        // 파싱된 경로 점들을 알고리즘 데이터에 저장
                        algorithmData[algorithmName].waypoints = pathPoints.slice(); // 복사본 저장
                        console.log("Successfully loaded and parsed", algorithmName, "- Total waypoints:", pathPoints.length);
                        console.log("Stored waypoints for", algorithmName, ":", algorithmData[algorithmName].waypoints.length);
                    } else {
                        console.log("Failed to parse coordinates from", algorithmName);
                    }
                } else {
                    console.log("Failed to load uploaded file", algorithmName, "status:", xhr.status);
                }
            }
        };
        xhr.send();
    }

    // 웨이포인트 파일을 파싱하여 웨이포인트 목록에 추가하는 함수
    function loadWaypointsFromFile(fileUrl) {
        console.log("Loading waypoints from file:", fileUrl);

        var xhr = new XMLHttpRequest();
        xhr.open("GET", fileUrl);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 0 || xhr.status === 200) {
                    var lines = xhr.responseText.trim().split(/\r?\n/);
                    var addedCount = 0;

                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();

                        // 빈 줄이나 주석 건너뛰기
                        if (line === "" || line.startsWith("//") || line.startsWith("#") || line.startsWith("=")) {
                            continue;
                        }

                        // 좌표 패턴 찾기: 위도, 경도 형태
                        var coordinateMatch = line.match(/(\d+\.\d+)[,\s]+(\d+\.\d+)/);
                        if (coordinateMatch) {
                            var latitude = parseFloat(coordinateMatch[1]);
                            var longitude = parseFloat(coordinateMatch[2]);

                            // 유효한 GPS 좌표인지 확인
                            if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) {
                                addedCount++;
                                var waypoint = {
                                    name: "W" + addedCount,
                                    latitude: latitude,
                                    longitude: longitude,
                                    altitude: 10.0  // 기본 고도
                                };
                                waypoints.push(waypoint);
                                waypointListModel.append(waypoint);
                            }
                        } else
                        // 이미 변환된 형태: 위도 경도 고도
                        {
                            var parts = line.split(/[\s,]+/);
                            if (parts.length >= 2) {
                                var lat = parseFloat(parts[0]);
                                var lon = parseFloat(parts[1]);
                                var alt = parts.length >= 3 ? parseFloat(parts[2]) : 10.0;

                                if (lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
                                    addedCount++;
                                    var waypoint = {
                                        name: "W" + addedCount,
                                        latitude: lat,
                                        longitude: lon,
                                        altitude: alt
                                    };
                                    waypoints.push(waypoint);
                                    waypointListModel.append(waypoint);
                                }
                            }
                        }
                    }

                    console.log("Successfully loaded", addedCount, "waypoints from file");
                } else {
                    console.log("Failed to load waypoint file, status:", xhr.status);
                }
            }
        };
        xhr.send();
    }

    // 웨이포인트 파일 선택 다이얼로그
    FileDialog {
        id: waypointFileDialog
        title: "웨이포인트 파일 선택"
        nameFilters: ["Text files (*.txt)", "CSV files (*.csv)", "All files (*)"]
        onAccepted: {
            loadWaypointsFromFile(selectedFile);
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 30
        // contentHeight: scrollArea.implicitHeight

        Item {
            id: scrollArea
            width: parent.width
            height: columnLayout.implicitHeight
            // height: 1000

            ColumnLayout {
                id: columnLayout
                anchors.fill: parent
                spacing: 20

                // Header
                Text {
                    text: "비행 경로 계획"
                    color: "#dddddd"
                    font.pixelSize: 24
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 20

                    // 첫 번째 ColumnLayout: 웨이포인트 입력 및 목록
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: parent.width * 0.5
                        spacing: 20

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

                                // Add waypoint buttons
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 10
                                    spacing: 15

                                    Button {
                                        text: "웨이포인트 추가"
                                        Layout.preferredWidth: 140

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
                                            if (waypointNameField.text.trim() !== "" && latitudeField.text.trim() !== "" && longitudeField.text.trim() !== "") {
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

                                    Button {
                                        text: "파일로 Waypoint 목록 추가"
                                        Layout.preferredWidth: 200

                                        background: Rectangle {
                                            color: parent.pressed ? "#FF9800" : "#FFA726"
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
                                            waypointFileDialog.open();
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
                        spacing: 20

                        // Map section
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 420
                            color: "#3a3a3a"
                            radius: 10
                            border.color: "#555555"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Text {
                                    text: "웨이포인트 / 경로 계획 지도"
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

                                            onPressed: function (mouse) {
                                                startPoint = Qt.point(mouse.x, mouse.y);
                                                startCenter = waypointMap.center;
                                            }

                                            onPositionChanged: function (mouse) {
                                                if (pressed) {
                                                    var deltaX = mouse.x - startPoint.x;
                                                    var deltaY = mouse.y - startPoint.y;

                                                    // 화면 좌표 차이를 지리적 좌표 차이로 변환
                                                    var startCoord = waypointMap.toCoordinate(startPoint);
                                                    var currentCoord = waypointMap.toCoordinate(Qt.point(mouse.x, mouse.y));

                                                    var newLat = startCenter.latitude - (currentCoord.latitude - startCoord.latitude);
                                                    var newLng = startCenter.longitude - (currentCoord.longitude - startCoord.longitude);

                                                    waypointMap.center = QtPositioning.coordinate(newLat, newLng);
                                                }
                                            }
                                        }

                                        // 마우스 휠 줌 기능
                                        WheelHandler {
                                            onWheel: function (event) {
                                                var delta = event.angleDelta.y / 120; // 표준 휠 스크롤 단위
                                                var newZoomLevel = waypointMap.zoomLevel + delta * 0.5;

                                                // 줌 레벨 제한 검사
                                                if (newZoomLevel >= waypointMap.minimumZoomLevel && newZoomLevel <= waypointMap.maximumZoomLevel) {
                                                    waypointMap.zoomLevel = newZoomLevel;
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

                                        // 현재 경로 점들을 연결하는 경로선
                                        MapPolyline {
                                            id: currentWaypointPath
                                            line.color: "#FF9800" // 경로선 색상
                                            line.width: 3

                                            // 경로 점들이 변경될 때마다 업데이트
                                            Connections {
                                                target: planPage
                                                function onPathPointsChanged() {
                                                    var pathCoordinates = [];
                                                    console.log("Updating path with", currentPathPoints.length, "points");
                                                    for (var i = 0; i < currentPathPoints.length; i++) {
                                                        pathCoordinates.push(QtPositioning.coordinate(currentPathPoints[i].latitude, currentPathPoints[i].longitude));
                                                    }
                                                    currentWaypointPath.path = pathCoordinates;
                                                }
                                            }

                                            Component.onCompleted: {
                                                // 초기 경로 설정
                                                var pathCoordinates = [];
                                                for (var i = 0; i < currentPathPoints.length; i++) {
                                                    pathCoordinates.push(QtPositioning.coordinate(currentPathPoints[i].latitude, currentPathPoints[i].longitude));
                                                }
                                                currentWaypointPath.path = pathCoordinates;
                                            }
                                        }

                                        // 경로 점 마커들
                                        MapItemView {
                                            model: currentPathPoints
                                            delegate: MapQuickItem {
                                                coordinate: QtPositioning.coordinate(model.latitude, model.longitude)
                                                anchorPoint.x: 12
                                                anchorPoint.y: 12

                                                sourceItem: Rectangle {
                                                    width: 24
                                                    height: 24
                                                    radius: 12
                                                    color: "#2196F3" // 파란색 배경
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
                                                        font.pixelSize: 12
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
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 40

                                        background: Rectangle {
                                            color: parent.pressed ? "#555555" : "#404040"
                                            radius: 4
                                            border.color: "#666666"
                                            border.width: 1
                                        }

                                        contentItem: Item {
                                            anchors.fill: parent

                                            Image {
                                                id: wholeMapImage
                                                source: resourceManager.getUrl("assets/icons/map/wholeMap_btn.png")
                                                fillMode: Image.PreserveAspectFit
                                                anchors.centerIn: parent
                                                width: 32
                                                height: 32
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                text: "◯"
                                                color: "white"
                                                font.pixelSize: 20
                                                font.bold: true
                                                anchors.centerIn: parent
                                                visible: wholeMapImage.status !== Image.Ready
                                            }
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

                                                if (maxDiff > 0.1)
                                                    waypointMap.zoomLevel = 10;
                                                else if (maxDiff > 0.05)
                                                    waypointMap.zoomLevel = 12;
                                                else if (maxDiff > 0.01)
                                                    waypointMap.zoomLevel = 14;
                                                else
                                                    waypointMap.zoomLevel = 16;
                                            }
                                        }
                                    }

                                    Button {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 40

                                        background: Rectangle {
                                            color: parent.pressed ? "#555555" : "#404040"
                                            radius: 4
                                            border.color: "#666666"
                                            border.width: 1
                                        }

                                        contentItem: Item {
                                            anchors.fill: parent

                                            Image {
                                                id: zoomInImage
                                                source: resourceManager.getUrl("assets/icons/map/zoomIn_btn.png")
                                                fillMode: Image.PreserveAspectFit
                                                anchors.centerIn: parent
                                                width: 32
                                                height: 32
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                text: "+"
                                                color: "white"
                                                font.pixelSize: 20
                                                font.bold: true
                                                anchors.centerIn: parent
                                                visible: zoomInImage.status !== Image.Ready
                                            }
                                        }

                                        onClicked: {
                                            if (waypointMap.zoomLevel < 18) {
                                                waypointMap.zoomLevel += 1;
                                            }
                                        }
                                    }

                                    Button {
                                        Layout.preferredWidth: 50
                                        Layout.preferredHeight: 40

                                        background: Rectangle {
                                            color: parent.pressed ? "#555555" : "#404040"
                                            radius: 4
                                            border.color: "#666666"
                                            border.width: 1
                                        }

                                        contentItem: Item {
                                            anchors.fill: parent

                                            Image {
                                                id: zoomOutImage
                                                source: resourceManager.getUrl("assets/icons/map/zoomOut_btn.png")
                                                fillMode: Image.PreserveAspectFit
                                                anchors.centerIn: parent
                                                width: 32
                                                height: 32
                                                visible: status === Image.Ready
                                            }

                                            Text {
                                                text: "-"
                                                color: "white"
                                                font.pixelSize: 20
                                                font.bold: true
                                                anchors.centerIn: parent
                                                visible: zoomOutImage.status !== Image.Ready
                                            }
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

                        // 미션 경로 알고리즘
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            color: "#3a3a3a"
                            radius: 10
                            border.color: "#555555"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Text {
                                    text: "경로 계획 알고리즘"
                                    color: "white"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: algorithmListModel
                                    delegate: Rectangle {
                                        width: ListView.view.width
                                        height: 50
                                        color: "#4a4a4a"
                                        radius: 5
                                        border.color: "#666666"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 15

                                            Text {
                                                text: model.name
                                                color: "white"
                                                font.pixelSize: 14
                                                font.bold: true
                                                Layout.fillWidth: true
                                            }

                                            Button {
                                                text: "적용"
                                                Layout.preferredWidth: 60
                                                Layout.preferredHeight: 30

                                                background: Rectangle {
                                                    color: currentAlgorithm === model.name ? "#9E9E9E" : (parent.pressed ? "#388E3C" : "#4CAF50")
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
                                                    loadPathFromFile(model.name);
                                                    currentAlgorithm = model.name;
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
                                                }

                                                onClicked: {
                                                    algorithmListModel.remove(index);
                                                }
                                            }
                                        }
                                    }
                                }

                                Button {
                                    text: "경로 계획 알고리즘 추가"
                                    Layout.preferredWidth: 200
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 10
                                    background: Rectangle {
                                        color: parent.pressed ? "#388E3C" : "#4CAF50"
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
                                        var component = Qt.createComponent("AlgorithmInputPanel.qml");
                                        var window = component.createObject(null);
                                        if (window !== null) {
                                            window.onAccepted.connect(function (algorithmName, fileUrl) {
                                                // 알고리즘 목록에 추가
                                                algorithmListModel.append({
                                                    "name": algorithmName
                                                });

                                                // 파일 읽기 및 좌표 파싱
                                                loadAndParseUploadedFile(algorithmName, fileUrl);

                                                console.log("알고리즘 추가 완료 - 이름:", algorithmName, "파일:", fileUrl);
                                            });
                                            window.show();
                                        } else {
                                            console.log("윈도우 생성 실패:", component.errorString());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 여백
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
