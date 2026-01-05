import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: pfdRoot
    anchors.fill: parent
    color: "#1a1a1a"

    // PFD 컨트롤러 연결
    Connections {
        target: pfdManager

        function onPitchAngleChanged(pitchAngle) {
            pfdRoot.pitchAngle = pitchAngle;
        }

        function onRollAngleChanged(rollAngle) {
            pfdRoot.rollAngle = rollAngle;
        }

        function onAltitudeChanged(altitude) {
            pfdRoot.altitude = altitude;
        }

        function onAirspeedChanged(airspeed) {
            pfdRoot.airspeed = airspeed;
        }

        function onHeadingChanged(heading) {
            pfdRoot.heading = heading;
        }
    }

    // PFD 크기와 위치를 위한 속성
    property real pitchAngle: 0  // 피치 각도 (도)
    property real rollAngle: 0   // 롤 각도 (도)
    property real altitude: 0    // 고도 (미터)
    property real airspeed: 0    // 대기속도 (노트)
    property real heading: 0     // 방위각 (도)

    Rectangle {
        anchors.fill: parent
        color: "#2a2a2a"
        radius: 8
    }

    // 수평계 (Artificial Horizon)
    Rectangle {
        id: horizon
        anchors.fill: parent
        // width: parent.width * 2
        // height: parent.height * 2
        anchors.centerIn: parent
        clip: true

        // 수평계 크기가 변경될 때마다 다시 그리기
        onWidthChanged: pitchGuidelines.requestPaint()
        onHeightChanged: pitchGuidelines.requestPaint()

        // 하늘색 부분 (위쪽)
        Rectangle {
            id: sky
            width: parent.width
            height: parent.height / 2
            color: "#87CEEB"  // 하늘색
            anchors.top: parent.top
        }

        // 갈색 부분 (아래쪽)
        Rectangle {
            id: ground
            width: parent.width
            height: parent.height / 2
            color: "#8B4513"  // 갈색
            anchors.bottom: parent.bottom
        }

        // 피치 가이드라인
        Canvas {
            id: pitchGuidelines
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 2;
                ctx.fillStyle = "#FFFFFF";
                ctx.font = Math.max(12, width / 80) + "px Arial";
                ctx.textAlign = "center";

                var pitchOffset = (pfdRoot.pitchAngle / 10) * (height / 2);
                var centerX = width / 2;

                // 중심선
                ctx.beginPath();
                ctx.moveTo(0, height / 2 + pitchOffset);
                ctx.lineTo(width, height / 2 + pitchOffset);
                ctx.stroke();

                for (var i = 1; i <= 7; i++) {
                    var angle = i * 5;
                    var y1 = height / 2 + pitchOffset - angle * (height / 2) / 30;
                    var y2 = height / 2 + pitchOffset + angle * (height / 2) / 30;
                    var isTenMultiple = (angle % 10 === 0);
                    var lineLength = isTenMultiple ? 50 : 25;
                    var endLineLength = Math.max(10, width / 40);
                    var textOffset = 15;

                    // alpha 계산: 0~20도 구간에서 1.0~0.1로 선형 감소, 20도 이상은 0.1 고정
                    var alpha = 1.0;
                    if (angle <= 20) {
                        alpha = 1.0 - 0.9 * (angle / 20);
                    } else {
                        alpha = 0.1;
                    }
                    ctx.globalAlpha = alpha;

                    if (y1 > 0) {
                        // 위쪽 가이드라인
                        ctx.beginPath();
                        ctx.moveTo(centerX - lineLength, y1);
                        ctx.lineTo(centerX + lineLength, y1);
                        ctx.stroke();
                        // 가이드라인 끝의 작은 선
                        ctx.beginPath();
                        ctx.moveTo(centerX - lineLength, y1);
                        ctx.lineTo(centerX - lineLength - endLineLength, y1);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(centerX + lineLength, y1);
                        ctx.lineTo(centerX + lineLength + endLineLength, y1);
                        ctx.stroke();
                        // 10의 배수일 때 각도 표시
                        if (isTenMultiple) {
                            ctx.fillText(angle.toString(), centerX - lineLength - endLineLength - textOffset, y1 + 4);
                            ctx.fillText(angle.toString(), centerX + lineLength + endLineLength + textOffset, y1 + 4);
                        }
                    }
                    if (y2 < height) {
                        // 아래쪽 가이드라인
                        ctx.beginPath();
                        ctx.moveTo(centerX - lineLength, y2);
                        ctx.lineTo(centerX + lineLength, y2);
                        ctx.stroke();
                        // 가이드라인 끝의 작은 선
                        ctx.beginPath();
                        ctx.moveTo(centerX - lineLength, y2);
                        ctx.lineTo(centerX - lineLength - endLineLength, y2);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(centerX + lineLength, y2);
                        ctx.lineTo(centerX + lineLength + endLineLength, y2);
                        ctx.stroke();
                        // 10의 배수일 때 각도 표시
                        if (isTenMultiple) {
                            ctx.fillText(angle.toString(), centerX - lineLength - endLineLength - textOffset, y2 + 4);
                            ctx.fillText(angle.toString(), centerX + lineLength + endLineLength + textOffset, y2 + 4);
                        }
                    }
                    ctx.globalAlpha = 1.0; // alpha 초기화
                }
            }
        }

        // 롤 각도에 따른 회전
        transform: Rotation {
            origin.x: horizon.width / 2
            origin.y: horizon.height / 2
            angle: -pfdRoot.rollAngle
        }
    }

    // 롤 다이얼 (상단 반원형)
    Canvas {
        id: rollDial
        width: 350
        height: 220
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -90
        z: 10
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var centerX = width / 2;
            var centerY = height * 0.95;
            var radius = Math.min(width, height * 2) / 2 - 8;
            // 반원 아크
            ctx.save();
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, Math.PI + Math.PI / 4, -Math.PI / 4, false); // -45~+45도
            ctx.lineWidth = 2;
            ctx.strokeStyle = "#fff";
            ctx.stroke();
            ctx.restore();
            // 눈금 및 각도 표시
            ctx.save();
            ctx.font = "bold 13px Arial";
            ctx.fillStyle = "#fff";
            ctx.textAlign = "center";
            for (var deg = -45; deg <= 45; deg += 15) {
                var rad = (Math.PI / 2) - (deg * Math.PI / 180);
                var x1 = centerX + Math.cos(rad) * (radius - 0);
                var y1 = centerY - Math.sin(rad) * (radius - 0);
                var x2 = centerX + Math.cos(rad) * (radius + 12);
                var y2 = centerY - Math.sin(rad) * (radius + 12);
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.lineWidth = 2;
                ctx.strokeStyle = "#fff";
                ctx.stroke();
                // 각도 숫자
                var labelX = centerX + Math.cos(rad) * (radius + 22);
                var labelY = centerY - Math.sin(rad) * (radius + 22);
                ctx.fillText(Math.abs(deg).toString(), labelX, labelY + 5);
            }
            // 현재 롤 각도 인디케이터(삼각형)
            ctx.save();
            var rollRad = (Math.PI / 2) - (pfdRoot.rollAngle * Math.PI / 180);

            // 화살표 꼭짓점(0 바로 아래)
            var tipX = centerX + Math.cos(rollRad) * (radius + 22);
            var tipY = centerY - Math.sin(rollRad) * (radius + 22) + 23;
            // 밑변(안쪽)
            var baseLeftX = centerX + Math.cos(rollRad + Math.PI / 2.5) * 12 + Math.cos(rollRad) * (radius + 2);
            var baseLeftY = centerY - Math.sin(rollRad + Math.PI / 2.5) * 12 - Math.sin(rollRad) * (radius + 2) + 20;
            var baseRightX = centerX + Math.cos(rollRad - Math.PI / 2.5) * 12 + Math.cos(rollRad) * (radius + 2);
            var baseRightY = centerY - Math.sin(rollRad - Math.PI / 2.5) * 12 - Math.sin(rollRad) * (radius + 2) + 20;
            ctx.beginPath();
            ctx.moveTo(tipX, tipY);
            ctx.lineTo(baseLeftX, baseLeftY);
            ctx.lineTo(baseRightX, baseRightY);
            ctx.closePath();
            ctx.globalAlpha = 1.0;
            ctx.strokeStyle = "#fff";
            ctx.lineWidth = 2;
            ctx.stroke();
            ctx.restore();
        }
    }

    // 조준점 (Aiming Reticle)
    Canvas {
        id: reticle
        width: 120
        height: 30
        anchors.centerIn: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = "#111";
            ctx.lineWidth = 4;
            // 왼쪽 ㄱ자
            ctx.beginPath();
            ctx.moveTo(10, height / 2);
            ctx.lineTo(40, height / 2);
            ctx.lineTo(40, height / 2 + 10);
            ctx.stroke();
            // 오른쪽 ㄱ자
            ctx.beginPath();
            ctx.moveTo(width - 10, height / 2);
            ctx.lineTo(width - 40, height / 2);
            ctx.lineTo(width - 40, height / 2 + 10);
            ctx.stroke();
            // 중앙 점
            ctx.fillStyle = "#111";
            ctx.fillRect(width / 2 - 3, height / 2 - 3, 6, 6);
        }
    }

    // 속도 테이프(왼쪽)
    Item {
        id: airspeedTape
        width: 70
        height: 220
        anchors.verticalCenter: reticle.verticalCenter
        anchors.right: reticle.left
        anchors.rightMargin: 120 // 더 넓힘
        z: 9
        // 전체 박스 테두리
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#fff"
            border.width: 2
            radius: 0 // 직각
            z: 8
        }
        // 눈금 표시
        Canvas {
            id: airspeedScale
            anchors.fill: parent
            z: 9
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.font = "14px Arial";
                ctx.fillStyle = "#fff";
                ctx.textAlign = "right";
                var centerValue = Math.round(pfdRoot.airspeed);
                var step = 2;
                var range = 5; // 위아래 5칸씩
                var centerY = height / 2;
                for (var i = -range; i <= range; i++) {
                    var v = centerValue + i * step;
                    var y = centerY + i * 32;
                    ctx.beginPath();
                    ctx.moveTo(width - 30, y);
                    ctx.lineTo(width - 10, y);
                    ctx.stroke();
                    ctx.fillText(v.toString(), width - 32, y + 5);
                }
            }
        }
        // 중앙 화살표 박스 (속도)
        Canvas {
            width: 48
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 10
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width - 16, 0);
                ctx.lineTo(width, height / 2);
                ctx.lineTo(width - 16, height);
                ctx.lineTo(0, height);
                ctx.closePath();
                ctx.fillStyle = "#222";
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.fill();
                ctx.stroke();
                ctx.font = "20px Arial";
                ctx.fillStyle = "#fff";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(Math.round(pfdRoot.airspeed), width / 2 - 4, height / 2);
            }
        }
    }
    // 고도 테이프(오른쪽)
    Item {
        id: altitudeTape
        width: 90
        height: 220
        anchors.verticalCenter: reticle.verticalCenter
        anchors.left: reticle.right
        anchors.leftMargin: 120 // 더 넓힘
        z: 9
        // 전체 박스 테두리
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#fff"
            border.width: 2
            radius: 0 // 직각
            z: 8
        }
        // 눈금 표시
        Canvas {
            id: altitudeScale
            anchors.fill: parent
            z: 9
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.font = "14px Arial";
                ctx.fillStyle = "#fff";
                ctx.textAlign = "left";
                var centerValue = Math.round(pfdRoot.altitude);
                var step = 20;
                var range = 5;
                var centerY = height / 2;
                for (var i = -range; i <= range; i++) {
                    var v = centerValue + i * step;
                    var y = centerY + i * 32;
                    ctx.beginPath();
                    ctx.moveTo(10, y);
                    ctx.lineTo(40, y);
                    ctx.stroke();
                    ctx.fillText(v.toString(), 44, y + 5);
                }
            }
        }
        // 중앙 화살표 박스 (고도)
        Canvas {
            width: 60
            height: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            z: 10
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.beginPath();
                ctx.moveTo(width, 0);
                ctx.lineTo(16, 0);
                ctx.lineTo(0, height / 2);
                ctx.lineTo(16, height);
                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fillStyle = "#222";
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.fill();
                ctx.stroke();
                ctx.font = "20px Arial";
                ctx.fillStyle = "#fff";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(Math.round(pfdRoot.altitude), width / 2 + 4, height / 2);
            }
        }
    }

    // 최상단 Yaw(Heading) 테이프
    Item {
        id: headingTape
        width: parent.width
        height: 48
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100
        // 눈금 표시
        Canvas {
            id: headingScale
            anchors.fill: parent

            // heading 값이 변경될 때마다 다시 그리기
            Connections {
                target: pfdRoot
                function onHeadingChanged() {
                    headingScale.requestPaint();
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var centerX = width / 2;
                var degPerPx = width / 100; // 화면 전체 너비를 100도로 설정
                var centerHeading = Math.round(pfdRoot.heading) % 360;
                var displayRange = 50; // 중심에서 좌우로 50도씩 (총 100도)

                // 5도 간격 눈금 그리기
                // 실제 방위각의 5도 배수에 맞춰서 표시
                var startDeg5 = Math.floor((centerHeading - displayRange) / 5) * 5;
                var endDeg5 = Math.ceil((centerHeading + displayRange) / 5) * 5;

                for (var currentDeg5 = startDeg5; currentDeg5 <= endDeg5; currentDeg5 += 5) {
                    var normalizedDeg5 = (currentDeg5 + 360) % 360;
                    var relativePos5 = currentDeg5 - centerHeading;
                    var x5 = centerX + relativePos5 * degPerPx;

                    if (x5 >= 0 && x5 <= width) {
                        ctx.strokeStyle = "#fff";
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(x5, 0);
                        ctx.lineTo(x5, 12);
                        ctx.stroke();
                    }
                }

                // 15도 간격 숫자/문자 표시
                // 실제 방위각의 15도 배수에 맞춰서 표시
                var startDeg = Math.floor((centerHeading - displayRange) / 15) * 15;
                var endDeg = Math.ceil((centerHeading + displayRange) / 15) * 15;

                for (var currentDeg = startDeg; currentDeg <= endDeg; currentDeg += 15) {
                    var normalizedDeg = (currentDeg + 360) % 360;
                    var relativePos = currentDeg - centerHeading;
                    var x = centerX + relativePos * degPerPx;

                    if (x >= 30 && x <= width - 30) {
                        // 가장자리 여백 확보
                        // 15도 간격 눈금은 더 길게
                        ctx.strokeStyle = "#fff";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, 18);
                        ctx.stroke();

                        // 숫자/문자 표시
                        ctx.font = "bold 16px Arial";
                        ctx.fillStyle = "#fff";
                        ctx.textAlign = "center";
                        var label = "";
                        if (normalizedDeg === 0)
                            label = "N";
                        else if (normalizedDeg === 90)
                            label = "E";
                        else if (normalizedDeg === 180)
                            label = "S";
                        else if (normalizedDeg === 270)
                            label = "W";
                        else if (normalizedDeg === 45)
                            label = "NE";
                        else if (normalizedDeg === 135)
                            label = "SE";
                        else if (normalizedDeg === 225)
                            label = "SW";
                        else if (normalizedDeg === 315)
                            label = "NW";
                        else if (normalizedDeg % 30 === 0)
                            label = normalizedDeg.toString();
                        else
                            // 30도 배수는 숫자로
                            label = normalizedDeg.toString(); // 나머지 15도 간격도 숫자로 표시

                        ctx.fillText(label, x, 36);
                    }
                }

                // 중앙 박스 (검은색, 불투명) - 높이를 반으로 줄이고 하단에 배치
                var boxHeight = height / 2;
                ctx.fillStyle = "#222";
                ctx.globalAlpha = 1.0;
                ctx.fillRect(centerX - 38, boxHeight, 76, boxHeight);
                ctx.globalAlpha = 1.0;
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.strokeRect(centerX - 38, boxHeight, 76, boxHeight);

                // 박스 위 삼각형 포인터 (아래쪽을 가리키도록 뒤집음)
                ctx.beginPath();
                ctx.moveTo(centerX, boxHeight - 12); // 삼각형 꼭짓점 (아래쪽)
                ctx.lineTo(centerX - 10, boxHeight); // 왼쪽 모서리 (박스 왼쪽 끝)
                ctx.lineTo(centerX + 10, boxHeight); // 오른쪽 모서리 (박스 오른쪽 끝)
                ctx.closePath();
                ctx.fillStyle = "#222";
                ctx.fill();
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 1;
                ctx.stroke();

                // 현재 heading 값
                ctx.font = "bold 22px Arial";
                ctx.fillStyle = "#fff";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(Math.round(pfdRoot.heading).toString().padStart(3, '0'), centerX, boxHeight + boxHeight / 2);
                // 상단 구분선
                ctx.beginPath();
                ctx.moveTo(0, 1);
                ctx.lineTo(width, 1);
                ctx.strokeStyle = "#fff";
                ctx.lineWidth = 2;
                ctx.stroke();
            }
        }
    }

    // 시뮬레이션 토글 버튼 (우측 상단)
    // Button {
    //     id: simToggleBtn
    //     text: "시뮬레이션 시작/정지"
    //     anchors.top: parent.top
    //     anchors.right: parent.right
    //     anchors.bottomMargin: 16
    //     anchors.rightMargin: 16
    //     z: 200
    //     onClicked: pfdManager.toggleSimulation()
    // }
}
