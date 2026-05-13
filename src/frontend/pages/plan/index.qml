import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs
import QtWebEngine 1.10
import Colors 1.0

Rectangle {
    id: planPage
    color: Colors.backgroundSecondary

    // ──────────────────────────────────────────────
    // 데이터 모델
    // ──────────────────────────────────────────────
    property var waypoints: []

    ListModel { id: waypointListModel }

    // ──────────────────────────────────────────────
    // 지도 동기화
    // ──────────────────────────────────────────────
    function syncMap() {
        mapView.runJavaScript("updateWaypoints(" + JSON.stringify(waypoints) + ")");
    }

    // ──────────────────────────────────────────────
    // Waypoint 추가
    // ──────────────────────────────────────────────
    function addWaypoint(name, lat, lon, alt) {
        var wp = {
            name: name,
            latitude: lat,
            longitude: lon,
            altitude: alt
        };
        waypoints.push(wp);
        waypointListModel.append(wp);
        syncMap();
    }

    // ──────────────────────────────────────────────
    // CSV 파싱 및 일괄 등록
    // ──────────────────────────────────────────────
    function parseAndLoadCSV(fileUrl) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", fileUrl);
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 0 && xhr.status !== 200) {
                console.log("CSV 로드 실패:", xhr.status);
                return;
            }

            var lines = xhr.responseText.trim().split(/\r?\n/);
            var count = 0;

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "" || line.startsWith("#") || line.startsWith("//")) continue;

                // 쉼표 또는 공백/탭 구분
                var parts = line.indexOf(",") >= 0
                    ? line.split(",")
                    : line.split(/\s+/);

                parts = parts.map(function(p) { return p.trim(); });

                // 헤더 행 감지 (첫 토큰이 숫자가 아니면 skip)
                if (i === 0 && isNaN(parseFloat(parts[0]))) continue;

                var lat, lon, alt, name;

                if (parts.length >= 4) {
                    // name, lat, lon, alt
                    name = parts[0];
                    lat  = parseFloat(parts[1]);
                    lon  = parseFloat(parts[2]);
                    alt  = parseFloat(parts[3]);
                } else if (parts.length === 3) {
                    // lat, lon, alt
                    lat  = parseFloat(parts[0]);
                    lon  = parseFloat(parts[1]);
                    alt  = parseFloat(parts[2]);
                    name = "";
                } else if (parts.length === 2) {
                    // lat, lon
                    lat  = parseFloat(parts[0]);
                    lon  = parseFloat(parts[1]);
                    alt  = 10.0;
                    name = "";
                } else {
                    continue;
                }

                if (isNaN(lat) || isNaN(lon)) continue;
                if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;

                count++;
                var autoName = name !== "" ? name : "W" + (waypoints.length + 1);
                var wp = { name: autoName, latitude: lat, longitude: lon, altitude: isNaN(alt) ? 10.0 : alt };
                waypoints.push(wp);
                waypointListModel.append(wp);
            }

            if (count > 0) syncMap();
            console.log("CSV 로드 완료:", count, "개 waypoint 등록");
        };
        xhr.send();
    }

    // ──────────────────────────────────────────────
    // CSV 파일 선택 다이얼로그
    // ──────────────────────────────────────────────
    FileDialog {
        id: csvFileDialog
        title: "CSV / TXT 파일 선택"
        nameFilters: ["CSV files (*.csv)", "Text files (*.txt)", "All files (*)"]
        onAccepted: parseAndLoadCSV(selectedFile)
    }

    // ══════════════════════════════════════════════
    // 지도 (전체 화면)
    // ══════════════════════════════════════════════
    WebEngineView {
        id: mapView
        anchors.fill: parent
        url: planMapServer.mapUrl()
        settings.javascriptEnabled: true
        settings.localContentCanAccessRemoteUrls: true
        settings.localContentCanAccessFileUrls: true
    }

    // ══════════════════════════════════════════════
    // 햄버거 버튼
    // ══════════════════════════════════════════════
    Rectangle {
        id: hamburgerBtn
        z: 10
        x: 16
        y: 16
        width: 44
        height: 44
        radius: 8
        color: hamburgerMouse.containsMouse ? "#555555" : "#333333"
        border.color: "#666666"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 5

            Repeater {
                model: 3
                Rectangle {
                    width: 22
                    height: 2
                    radius: 1
                    color: "white"
                }
            }
        }

        MouseArea {
            id: hamburgerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: waypointPanel.visible = !waypointPanel.visible
        }
    }

    // ══════════════════════════════════════════════
    // Waypoint 패널 (오버레이)
    // ══════════════════════════════════════════════
    Rectangle {
        id: waypointPanel
        z: 9
        x: 16
        y: 72
        width: 440
        height: Math.min(implicitHeight, planPage.height - 88)
        visible: false
        color: "#1e1e1e"
        radius: 10
        border.color: "#444444"
        border.width: 1

        // 그림자 효과용 뒤 Rectangle
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: "#00000060"
            border.width: 3
            z: -1
        }

        implicitHeight: panelColumn.implicitHeight + 24

        ColumnLayout {
            id: panelColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 10

            // ── 헤더 ──
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Waypoints"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: waypointListModel.count + " 개"
                    color: "#aaaaaa"
                    font.pixelSize: 13
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? "#555555" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#aaaaaa"
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: waypointPanel.visible = false
                    }
                }
            }

            // ── 구분선 ──
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2e2e2e" }

            // ── 입력 폼 (한 줄) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                TextField {
                    id: wpName
                    Layout.preferredWidth: 72
                    placeholderText: "이름"
                    color: "white"
                    font.pixelSize: 12
                    background: Rectangle { color: "#252525"; border.color: "#3a3a3a"; border.width: 1; radius: 4 }
                }

                TextField {
                    id: wpLat
                    Layout.fillWidth: true
                    placeholderText: "위도"
                    color: "white"
                    font.pixelSize: 12
                    validator: DoubleValidator { bottom: -90; top: 90; decimals: 8 }
                    background: Rectangle { color: "#252525"; border.color: "#3a3a3a"; border.width: 1; radius: 4 }
                }

                TextField {
                    id: wpLon
                    Layout.fillWidth: true
                    placeholderText: "경도"
                    color: "white"
                    font.pixelSize: 12
                    validator: DoubleValidator { bottom: -180; top: 180; decimals: 8 }
                    background: Rectangle { color: "#252525"; border.color: "#3a3a3a"; border.width: 1; radius: 4 }
                }

                TextField {
                    id: wpAlt
                    Layout.preferredWidth: 58
                    placeholderText: "고도(m)"
                    color: "white"
                    font.pixelSize: 12
                    validator: DoubleValidator { bottom: -500; top: 50000; decimals: 2 }
                    background: Rectangle { color: "#252525"; border.color: "#3a3a3a"; border.width: 1; radius: 4 }
                }

                Rectangle {
                    width: 52
                    height: 34
                    radius: 5
                    color: addMouse.containsMouse ? "#2d6a30" : "#2e7d32"

                    Text {
                        anchors.centerIn: parent
                        text: "추가"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var latStr = wpLat.text.trim();
                            var lonStr = wpLon.text.trim();
                            if (latStr === "" || lonStr === "") return;

                            var lat = parseFloat(latStr);
                            var lon = parseFloat(lonStr);
                            var alt = wpAlt.text.trim() !== "" ? parseFloat(wpAlt.text) : 10.0;
                            var name = wpName.text.trim() !== "" ? wpName.text.trim() : "W" + (waypoints.length + 1);

                            addWaypoint(name, lat, lon, alt);

                            wpName.text = "";
                            wpLat.text = "";
                            wpLon.text = "";
                            wpAlt.text = "";
                        }
                    }
                }
            }

            // ── CSV 업로드 버튼 ──
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 5
                color: csvMouse.containsMouse ? "#1b5e20" : "#2e7d32"

                Text {
                    anchors.centerIn: parent
                    text: "CSV / TXT 파일로 일괄 등록"
                    color: "#a5d6a7"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: csvMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: csvFileDialog.open()
                }
            }

            // ── 구분선 ──
            Rectangle { Layout.fillWidth: true; height: 1; color: "#2e2e2e" }

            // ── Waypoint 목록 헤더 ──
            RowLayout {
                Layout.fillWidth: true

                Text { text: "#";    color: "#555"; font.pixelSize: 11; Layout.preferredWidth: 24 }
                Text { text: "이름"; color: "#555"; font.pixelSize: 11; Layout.preferredWidth: 70 }
                Text { text: "위도"; color: "#555"; font.pixelSize: 11; Layout.fillWidth: true }
                Text { text: "경도"; color: "#555"; font.pixelSize: 11; Layout.fillWidth: true }
                Text { text: "고도"; color: "#555"; font.pixelSize: 11; Layout.preferredWidth: 50 }
                Item  { Layout.preferredWidth: 28 }
            }

            // ── Waypoint 목록 ──
            ListView {
                id: waypointListView
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 260)
                clip: true
                model: waypointListModel

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    width: waypointListView.width
                    height: 34
                    color: index % 2 === 0 ? "#1a1a1a" : "#222222"
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 0

                        Text {
                            text: index + 1
                            color: "#4caf50"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.preferredWidth: 24
                        }

                        Text {
                            text: model.name
                            color: "#e0e0e0"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.preferredWidth: 70
                        }

                        Text {
                            text: model.latitude.toFixed(5)
                            color: "#9e9e9e"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.longitude.toFixed(5)
                            color: "#9e9e9e"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }

                        Text {
                            text: model.altitude + "m"
                            color: "#757575"
                            font.pixelSize: 11
                            Layout.preferredWidth: 50
                        }

                        Rectangle {
                            width: 24
                            height: 22
                            radius: 3
                            color: delMouse.containsMouse ? "#333333" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delMouse.containsMouse ? "#ef9a9a" : "#616161"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    waypoints.splice(index, 1);
                                    waypointListModel.remove(index);
                                    syncMap();
                                }
                            }
                        }
                    }
                }
            }

            // ── 하단 버튼들 ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 5
                    color: focusMouse.containsMouse ? "#1b5e20" : "#2e7d32"

                    Text {
                        anchors.centerIn: parent
                        text: "전체 보기"
                        color: "white"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: focusMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mapView.runJavaScript("focusWaypoints()")
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 5
                    color: clearMouse.containsMouse ? "#2a2a2a" : "#1e1e1e"
                    border.color: "#3a3a3a"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "모두 삭제"
                        color: clearMouse.containsMouse ? "#ef9a9a" : "#757575"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            waypoints = [];
                            waypointListModel.clear();
                            mapView.runJavaScript("clearWaypoints()");
                        }
                    }
                }
            }

            // 하단 여백
            Item { height: 4 }
        }
    }
}
