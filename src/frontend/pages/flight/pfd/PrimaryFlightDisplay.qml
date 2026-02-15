import QtQuick 2.15
import QtQuick.Controls 2.15

// https://github.com/shadymeowy/QPrimaryFlightDisplay
// Python으로 작성된 것을 QML로 포팅

Item {
    id: root

    // Properties matching Python class
    property real pitch: 0          // radians
    property real roll: 0           // radians
    property real skipskid: 0       // -1 to 1
    property real heading: 0        // degrees
    property real airspeed: 0       // units
    property real groundspeed: 0    // ground speed
    property real alt: 0            // altitude
    property real vspeed: 0         // vertical speed
    property int fix_type: 0        // GPS fix type (0-6)
    property real zoom: 1.0

    // Internal properties
    property real scale: (Qt.platform.os === "osx" ? 2.0 : 1.0) * zoom
    property real dpi: 96

    // Colors
    property color fg: palette.windowText
    property color bsbr: palette.base
    property color hg: palette.highlight
    property color sky: "#4A90E2"
    property color ground: "#8B6F47"
    property color wrn: "#f67400"
    property color err: "#da4453"
    property color pst: "#27ae60"

    SystemPalette {
        id: palette
    }

    // Main canvas for drawing
    Canvas {
        id: mainCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.save();

            // Draw all components
            drawRegion(ctx, false);  // ground
            drawRegion(ctx, true);   // sky
            drawMarkers(ctx);
            drawCursor(ctx);
            drawSkipSkid(ctx);
            drawHeading(ctx);
            drawAirspeed(ctx);
            drawVSpeed(ctx);
            drawAltimeter(ctx);
            drawStatus(ctx);

            ctx.restore();
        }

        // Redraw when properties change
        Connections {
            target: root
            function onPitchChanged() {
                mainCanvas.requestPaint();
            }
            function onRollChanged() {
                mainCanvas.requestPaint();
            }
            function onSkipskidChanged() {
                mainCanvas.requestPaint();
            }
            function onHeadingChanged() {
                mainCanvas.requestPaint();
            }
            function onAirspeedChanged() {
                mainCanvas.requestPaint();
            }
            function onGroundspeedChanged() {
                mainCanvas.requestPaint();
            }
            function onAltChanged() {
                mainCanvas.requestPaint();
            }
            function onVspeedChanged() {
                mainCanvas.requestPaint();
            }
            function onFix_typeChanged() {
                mainCanvas.requestPaint();
            }
        }

        // Helper functions
        function drawStatus(ctx) {
            var w = width;
            var h = height;
            var s = scale;

            // GPS Fix Type indicator (text only)
            if (fix_type !== null && fix_type !== undefined) {
                ctx.save();

                // Determine color and text based on fix quality
                var fixColor;
                var fixText;
                if (fix_type === 0) {
                    fixColor = err;
                    fixText = "GPS: NO GPS";
                } else if (fix_type === 1) {
                    fixColor = err;
                    fixText = "GPS: NO FIX";
                } else if (fix_type === 2) {
                    fixColor = wrn;
                    fixText = "GPS: 2D FIX";
                } else if (fix_type === 3) {
                    fixColor = pst;
                    fixText = "GPS: 3D FIX";
                } else if (fix_type === 4) {
                    fixColor = pst;
                    fixText = "GPS: DGPS";
                } else if (fix_type === 5) {
                    fixColor = hg;
                    fixText = "GPS: RTK FLT";
                } else if (fix_type === 6) {
                    fixColor = hg;
                    fixText = "GPS: RTK FIX";
                } else {
                    fixColor = err;
                    fixText = "GPS: UNKNOWN";
                }

                // Draw text only
                // ctx.fillStyle = fixColor;
                ctx.fillStyle = "black";
                ctx.font = (14 * zoom) + "px Arial";
                ctx.textAlign = "right";
                ctx.textBaseline = "bottom";
                ctx.fillText(fixText, w - 10 * s, h - 10 * s);
                ctx.restore();
            }
        }

        function drawVSpeed(ctx) {
            var w = width;
            var h = height;
            var s = scale;
            var v = vspeed;
            var per = 30 * s;
            var inc = 0.5;
            var r = per / inc;
            var x2 = 15 * w / 16;
            var x1 = 15 * w / 16 - 40 * s - 10 * s;
            var y1 = 4 * h / 16;
            var y2 = h - y1;

            ctx.save();
            ctx.font = (12 * zoom) + "px Arial";

            // Background with transparency
            ctx.globalAlpha = 0.5;
            ctx.fillStyle = bsbr;
            ctx.fillRect(x1, y1, x2 - x1 - 10 * s, y2 - y1);
            ctx.globalAlpha = 1.0;

            ctx.strokeStyle = fg;
            ctx.lineWidth = 2 * s;
            ctx.strokeRect(x1, y1, x2 - x1 - 10 * s, y2 - y1);

            // Left edge line
            ctx.lineWidth = 3 * s;
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x1, y2);
            ctx.stroke();

            // Clip region for scale
            ctx.save();
            ctx.beginPath();
            ctx.rect(x1, y1, x2 - x1, y2 - y1);
            ctx.clip();

            var l1 = Math.floor(((y1 + y2) / 2 + v * r - y2) / per) - 1;
            var l2 = Math.floor(((y1 + y2) / 2 + v * r - y1) / per) + 1;

            for (var i = l1; i <= l2 + 1; i++) {
                var pos = -i * per + v * r;
                if ((i % 2) === 0) {
                    ctx.beginPath();
                    ctx.moveTo(x1, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x1 + 15 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();

                    ctx.fillStyle = fg;
                    ctx.textAlign = "left";
                    ctx.textBaseline = "middle";
                    ctx.fillText(Math.round(Math.abs(i * inc)).toString(), x1 + 18 * s, (y1 + y2) / 2 + pos);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(x1, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x1 + 8 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();
                }
            }

            ctx.restore();

            // Center value box
            ctx.fillStyle = bsbr;
            ctx.beginPath();
            ctx.moveTo(x2, (y1 + y2) / 2 - 15 * s);
            ctx.lineTo(x2, (y1 + y2) / 2 + 15 * s);
            ctx.lineTo(x1 - 33 * s, (y1 + y2) / 2 + 15 * s);
            ctx.lineTo(x1 - 33 * s, (y1 + y2) / 2 - 15 * s);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            ctx.font = (16 * zoom) + "px Arial";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillStyle = fg;
            ctx.fillText(Math.abs(v).toFixed(1), x2 - 8 * s, (y1 + y2) / 2);

            ctx.restore();
        }

        function drawAltimeter(ctx) {
            var w = width;
            var h = height;
            var s = scale;
            var v = alt;
            var per = 70 * s;
            var inc = 5;
            var r = per / inc;
            var x2 = 15 * w / 16 - 40 * s;
            var x1 = 15 * w / 16 - 90 * s - 40 * s;
            var y1 = h / 15 + 20 * s;
            var y2 = h - y1;

            ctx.save();
            ctx.font = (16 * zoom) + "px Arial";

            // Background
            ctx.globalAlpha = 0.5;
            ctx.fillStyle = bsbr;
            ctx.fillRect(x1, y1, x2 - x1 - 10 * s, y2 - y1);
            ctx.globalAlpha = 1.0;

            ctx.strokeStyle = fg;
            ctx.lineWidth = 2 * s;
            ctx.strokeRect(x1, y1, x2 - x1 - 10 * s, y2 - y1);

            // Left edge line
            ctx.lineWidth = 3 * s;
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x1, y2);
            ctx.stroke();

            // Clip region
            ctx.save();
            ctx.beginPath();
            ctx.rect(x1, y1, x2 - x1, y2 - y1);
            ctx.clip();

            var l1 = Math.floor(((y1 + y2) / 2 + v * r - y2) / per) - 1;
            var l2 = Math.floor(((y1 + y2) / 2 + v * r - y1) / per) + 1;

            for (var i = l1; i <= l2 + 1; i++) {
                var pos = -i * per + v * r;
                if ((i % 2) === 0) {
                    ctx.beginPath();
                    ctx.moveTo(x1, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x1 + 25 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();

                    ctx.fillStyle = fg;
                    ctx.textAlign = "left";
                    ctx.textBaseline = "middle";
                    ctx.fillText((i * inc).toString(), x1 + 33 * s, (y1 + y2) / 2 + pos);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(x1, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x1 + 15 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();
                }

                // Minor ticks
                for (var j = -5; j <= 5; j++) {
                    ctx.beginPath();
                    ctx.moveTo(x1, (y1 + y2) / 2 + pos + j / 5 * per);
                    ctx.lineTo(x1 + 8 * s, (y1 + y2) / 2 + pos + j / 5 * per);
                    ctx.stroke();
                }
            }

            ctx.restore();

            // Center value box
            ctx.fillStyle = bsbr;
            ctx.beginPath();
            ctx.moveTo(x2, (y1 + y2) / 2 - 25 * s);
            ctx.lineTo(x2, (y1 + y2) / 2 + 25 * s);
            ctx.lineTo(x1 + 33 * s, (y1 + y2) / 2 + 25 * s);
            ctx.lineTo(x1, (y1 + y2) / 2);
            ctx.lineTo(x1 + 33 * s, (y1 + y2) / 2 - 25 * s);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            ctx.font = (20 * zoom) + "px Arial";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillStyle = fg;
            ctx.fillText(Math.round(v).toString(), x2 - 33 * s, (y1 + y2) / 2);

            ctx.restore();
        }

        function drawAirspeed(ctx) {
            var w = width;
            var h = height;
            var s = scale;
            var v = airspeed;
            var per = 40 * s;
            var inc = 4;
            var r = per / inc;
            var x1 = w / 16;
            var x2 = x1 + 90 * s;
            var y1 = h / 15 + 20 * s;
            var y2 = h - y1 - 7 * s;

            ctx.save();

            // Background
            ctx.globalAlpha = 0.5;
            ctx.fillStyle = bsbr;
            ctx.fillRect(x1 + 10 * s, y1, x2 - x1 - 10 * s, y2 - y1);
            ctx.globalAlpha = 1.0;

            ctx.strokeStyle = fg;
            ctx.lineWidth = 2 * s;
            ctx.strokeRect(x1 + 10 * s, y1, x2 - x1 - 10 * s, y2 - y1);

            // Right edge line
            ctx.lineWidth = 3 * s;
            ctx.beginPath();
            ctx.moveTo(x2, y1);
            ctx.lineTo(x2, y2);
            ctx.stroke();

            // Clip region
            ctx.save();
            ctx.beginPath();
            ctx.rect(x1, y1, x2 - x1, y2 - y1);
            ctx.clip();

            var l1 = Math.floor(((y1 + y2) / 2 + v * r - y2) / per) - 1;
            var l2 = Math.floor(((y1 + y2) / 2 + v * r - y1) / per) + 1;

            for (var i = l1; i <= l2 + 1; i++) {
                var pos = -i * per + v * r;
                if ((i % 2) === 0) {
                    ctx.beginPath();
                    ctx.moveTo(x2, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x2 - 25 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();

                    ctx.fillStyle = fg;
                    ctx.textAlign = "right";
                    ctx.textBaseline = "middle";
                    ctx.font = (16 * zoom) + "px Arial";
                    ctx.fillText((i * inc).toString(), x2 - 33 * s, (y1 + y2) / 2 + pos);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(x2, (y1 + y2) / 2 + pos);
                    ctx.lineTo(x2 - 15 * s, (y1 + y2) / 2 + pos);
                    ctx.stroke();
                }
            }

            ctx.restore();

            // Center value box
            ctx.fillStyle = bsbr;
            ctx.beginPath();
            ctx.moveTo(x1, (y1 + y2) / 2 - 25 * s);
            ctx.lineTo(x1, (y1 + y2) / 2 + 25 * s);
            ctx.lineTo(x2 - 33 * s, (y1 + y2) / 2 + 25 * s);
            ctx.lineTo(x2, (y1 + y2) / 2);
            ctx.lineTo(x2 - 33 * s, (y1 + y2) / 2 - 25 * s);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            ctx.font = (20 * zoom) + "px Arial";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillStyle = fg;
            ctx.fillText(Math.round(v).toString(), x2 - 33 * s, (y1 + y2) / 2);

            // AS and GS text below
            ctx.font = (14 * zoom) + "px Arial";
            ctx.textAlign = "left";
            ctx.textBaseline = "top";
            ctx.fillStyle = fg;
            ctx.fillText("AS " + airspeed.toFixed(1), x1 + 10 * s, y2 + 10 * s);
            ctx.fillText("GS " + groundspeed.toFixed(1), x1 + 10 * s, y2 + 30 * s);

            ctx.restore();
        }

        function drawHeading(ctx) {
            var w = width;
            var h = height;
            var s = scale;

            if (heading === null || heading === undefined)
                return;

            var hd = -heading * Math.PI / 180;
            var x = Math.min(4 * w / 16, 4 * h / 16);

            ctx.save();
            ctx.lineWidth = 3 * s;
            ctx.strokeStyle = fg;

            ctx.globalAlpha = 0.5;
            ctx.fillStyle = bsbr;
            ctx.beginPath();
            ctx.arc(w / 2, 17 * h / 16, x, 0, 2 * Math.PI);
            ctx.fill();
            ctx.globalAlpha = 1.0;
            ctx.stroke();

            // Draw tick marks
            ctx.font = (16 * zoom) + "px Arial";
            for (var i = 0; i < 72; i++) {
                ctx.save();
                ctx.translate(w / 2, 17 * h / 16);
                ctx.rotate((i / 72) * 2 * Math.PI + hd);

                if ((i % 2) === 0) {
                    if ((Math.floor(i / 2) % 3) === 0) {
                        var t = (i / 2).toString();
                        if (i === 0)
                            t = "N";
                        else if (i === 18)
                            t = "E";
                        else if (i === 36)
                            t = "S";
                        else if (i === 54)
                            t = "W";

                        ctx.fillStyle = fg;
                        ctx.textAlign = "center";
                        ctx.textBaseline = "top";
                        ctx.fillText(t, 0, -x + 15 * s);
                    }
                    ctx.beginPath();
                    ctx.moveTo(0, -x);
                    ctx.lineTo(0, -x + 15 * s);
                    ctx.stroke();
                } else if (i === 9 || i === 27 || i === 45 || i === 63) {
                    ctx.strokeStyle = wrn;
                    ctx.lineWidth = 3 * s;
                    ctx.beginPath();
                    ctx.moveTo(0, -x);
                    ctx.lineTo(0, -x + 30 * s);
                    ctx.stroke();
                    ctx.strokeStyle = fg;
                } else {
                    ctx.beginPath();
                    ctx.moveTo(0, -x);
                    ctx.lineTo(0, -x + 7 * s);
                    ctx.stroke();
                }

                ctx.restore();
            }

            // Center line
            ctx.strokeStyle = hg;
            ctx.lineWidth = 2 * s;
            ctx.beginPath();
            ctx.moveTo(w / 2, 17 * h / 16 - x);
            ctx.lineTo(w / 2, 17 * h / 16 + x);
            ctx.stroke();

            // Pointer
            ctx.fillStyle = hg;
            ctx.lineWidth = 4 * s;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(w / 2 - 7 * s, 17 * h / 16 - x + 17 * s);
            ctx.lineTo(w / 2, 17 * h / 16 - x + 2 * s);
            ctx.lineTo(w / 2 + 7 * s, 17 * h / 16 - x + 17 * s);
            ctx.closePath();
            ctx.fill();

            // Outer circle
            ctx.strokeStyle = fg;
            ctx.lineWidth = 3 * s;
            ctx.beginPath();
            ctx.arc(w / 2, 17 * h / 16, x, 0, 2 * Math.PI);
            ctx.stroke();

            ctx.restore();
        }

        function drawMarkers(ctx) {
            var p = pitch;
            var s = scale;
            var r = 50;
            p *= ((50 / 5) * s) * 180 / Math.PI;

            for (var i = 1; i < 20; i++) {
                var size = 80 * s * ((1 / 4) * i + 1 / 2) * 10 / (5 + i);
                if (-(4 * r * 1.1 * s) < p + i * r * s && p + i * r * s < 4 * r * 1.1 * s) {
                    var alpha = 255 - 255 * Math.abs(p + i * r * s) / (4 * r * 1.1 * s);
                    drawMarker(ctx, p + i * r * s, (i % 2) === 0 ? size : 40 * s, "  " + (i * r / 10).toString(), alpha);
                }
                if (-(4 * r * 1.1 * s) < p - i * 50 * s && p - i * 50 * s < 4 * r * 1.1 * s) {
                    var alpha2 = 255 - 255 * Math.abs(p - i * r * s) / (4 * r * 1.1 * s);
                    drawMarker(ctx, p - i * r * s, (i % 2) === 0 ? size : 40 * s, "  " + (i * r / 10).toString(), alpha2);
                }
            }
        }

        function drawMarker(ctx, p, r, t, alpha) {
            var w = width;
            var h = height;
            var b = -roll;
            var s = scale;

            ctx.save();
            ctx.globalAlpha = alpha / 255;
            ctx.strokeStyle = fg;
            ctx.lineWidth = 3 * s;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.moveTo(w / 2 - p * Math.sin(b) - r * Math.cos(b), h / 2 + p * Math.cos(b) - r * Math.sin(b));
            ctx.lineTo(w / 2 - p * Math.sin(b) + r * Math.cos(b), h / 2 + p * Math.cos(b) + r * Math.sin(b));
            ctx.stroke();

            ctx.translate(w / 2, h / 2);
            ctx.rotate(b);

            ctx.fillStyle = fg;
            ctx.font = (16 * zoom) + "px Arial";
            ctx.textAlign = "left";
            ctx.textBaseline = "middle";
            ctx.fillText(t, r, p + 8 * s);

            ctx.restore();
        }

        function drawSkipSkid(ctx) {
            var w = width;
            var h = height;
            var b = -roll;
            var s = scale;
            var x = Math.min(w / 2 - 50 * s, h / 2 - 50 * s);

            ctx.save();
            ctx.strokeStyle = fg;
            ctx.fillStyle = fg;
            ctx.lineWidth = 3 * s;
            ctx.lineCap = "round";

            // Arc
            ctx.beginPath();
            ctx.arc(w / 2, h / 2, x, Math.PI + Math.PI / 4, 2 * Math.PI - Math.PI / 4);

            ctx.stroke();

            // Roll indicator
            if (b < -7 * Math.PI / 32 || b > 7 * Math.PI / 32) {
                var limitedB = b;
                if (b < -Math.PI / 3)
                    limitedB = -Math.PI / 3;
                if (b > Math.PI / 3)
                    limitedB = Math.PI / 3;

                if (-Math.PI / 4 < b && b < Math.PI / 4) {
                    ctx.strokeStyle = fg;
                    ctx.fillStyle = fg;
                } else if (-Math.PI / 3 < b && b < Math.PI / 3) {
                    ctx.strokeStyle = wrn;
                    ctx.fillStyle = wrn;
                } else {
                    ctx.strokeStyle = err;
                    ctx.fillStyle = err;
                    limitedB = b > 0 ? Math.PI / 3 : -Math.PI / 3;
                }
                ctx.lineWidth = 3 * s;
                ctx.beginPath();
                ctx.arc(w / 2, h / 2, x, Math.PI + Math.PI / 4, 2 * Math.PI - Math.PI / 4);
                ctx.stroke();
            }

            ctx.strokeStyle = fg;
            ctx.fillStyle = fg;

            // Center dot
            ctx.beginPath();
            ctx.arc(w / 2, h / 2 - x, 2 * s, 0, 2 * Math.PI);
            ctx.fill();

            // Angle markers
            var ps = [-Math.PI / 6, Math.PI / 6, Math.PI / 3, -Math.PI / 3, Math.PI / 4, -Math.PI / 4, Math.PI / 18, -Math.PI / 18, Math.PI / 9, -Math.PI / 9];

            ctx.font = (12 * zoom) + "px Arial";
            for (var idx = 0; idx < ps.length; idx++) {
                var a = ps[idx];
                if ((a < -Math.PI / 4 || a > Math.PI / 4) && !(b < -7 * Math.PI / 32 || b > 7 * Math.PI / 32))
                    continue;

                ctx.save();
                ctx.translate(w / 2, h / 2);
                ctx.rotate(a);

                ctx.fillStyle = fg;
                ctx.textAlign = "center";
                ctx.textBaseline = "bottom";
                ctx.fillText(Math.abs(Math.round(a / Math.PI * 180)).toString(), 0, -x - 10 * s);

                ctx.beginPath();
                ctx.arc(0, -x, 3 * s, 0, 2 * Math.PI);
                ctx.fill();

                ctx.restore();
            }

            // Ball indicator
            ctx.save();
            ctx.translate(w / 2, h / 2);
            ctx.rotate(b);

            ctx.strokeStyle = fg;
            ctx.fillStyle = fg;
            ctx.beginPath();
            ctx.arc(0, -x, 5 * s, 0, 2 * Math.PI);
            ctx.fill();

            var px = -20 * s - skipskid * 20 * s;
            ctx.fillRect(px, -x + 15 * s, 40 * s, 10 * s);

            ctx.restore();
            ctx.restore();
        }

        function drawCursor(ctx) {
            var w = width;
            var h = height;
            var s = scale;

            ctx.save();
            ctx.strokeStyle = hg;
            ctx.lineWidth = 8 * s;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            ctx.beginPath();
            ctx.moveTo(w / 2 - 70 * s, h / 2);
            ctx.lineTo(w / 2 - 40 * s, h / 2);
            ctx.lineTo(w / 2, h / 2 + 30 * s);
            ctx.lineTo(w / 2 + 40 * s, h / 2);
            ctx.lineTo(w / 2 + 70 * s, h / 2);
            ctx.stroke();

            ctx.fillStyle = hg;
            ctx.beginPath();
            ctx.arc(w / 2, h / 2, 4 * s, 0, 2 * Math.PI);
            ctx.fill();

            ctx.restore();
        }

        function computeHorizon(p, b) {
            var w = width;
            var h = height;
            var x1, y1, x2, y2;

            if (b !== Math.PI / 2 && b !== -Math.PI / 2) {
                x1 = 0;
                y1 = h / 2 - w / 2 * Math.tan(b) + p / Math.cos(b);
                x2 = w;
                y2 = h / 2 + w / 2 * Math.tan(b) + p / Math.cos(b);
            } else if (b === Math.PI / 2) {
                x1 = 0;
                y1 = -1;
                x2 = w;
                y2 = h + 1;
            } else if (b === -Math.PI / 2) {
                x1 = w;
                y1 = h + 1;
                x2 = 0;
                y2 = -1;
            }

            try {
                if (y1 > h) {
                    x1 = (h / 2 - p / Math.cos(b)) / Math.tan(b) + w / 2;
                    y1 = h;
                } else if (y1 < 0) {
                    x1 = (-h / 2 - p / Math.cos(b)) / Math.tan(b) + w / 2;
                    y1 = 0;
                }
                if (y2 > h) {
                    x2 = (h / 2 - p / Math.cos(b)) / Math.tan(b) + w / 2;
                    y2 = h;
                } else if (y2 < 0) {
                    x2 = (-h / 2 - p / Math.cos(b)) / Math.tan(b) + w / 2;
                    y2 = 0;
                }
            } catch (e)
            // Division by zero
            {}

            return {
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2
            };
        }

        function drawRegion(ctx, isSky) {
            var w = width;
            var h = height;
            var p = pitch;
            var b = -roll;
            var s = scale;
            var inv = !isSky;

            p *= ((50 / 5) * s) * 180 / Math.PI;

            if (isSky)
                p = -p;

            if (b >= 0) {
                inv ^= ((Math.floor(b / Math.PI) % 2) === 0);
                b = b % Math.PI;
            } else {
                inv ^= ((Math.floor(b / (-Math.PI)) % 2) === 0);
                b = b % (-Math.PI);
            }

            if (Math.PI / 2 < b) {
                b -= Math.PI;
                inv = !inv;
            } else if (b < -Math.PI / 2) {
                b += Math.PI;
                inv = !inv;
            }

            if (inv)
                p = -p;

            var horizon = computeHorizon(p, b);
            var points = [];

            points.push({
                x: horizon.x1,
                y: horizon.y1
            });

            if (inv) {
                if (0 > -p - Math.sin(b) * (-w / 2 + 0) - Math.cos(b) * (h / 2 - h))
                    points.push({
                        x: 0,
                        y: h
                    });
                if (0 > -p - Math.sin(b) * (-w / 2 + 0) - Math.cos(b) * (h / 2 - 0))
                    points.push({
                        x: 0,
                        y: 0
                    });
                if (0 > -p - Math.sin(b) * (-w / 2 + w) - Math.cos(b) * (h / 2 - 0))
                    points.push({
                        x: w,
                        y: 0
                    });
                if (0 > -p - Math.sin(b) * (-w / 2 + w) - Math.cos(b) * (h / 2 - h))
                    points.push({
                        x: w,
                        y: h
                    });
            } else {
                if (0 < -p - Math.sin(b) * (-w / 2 + 0) - Math.cos(b) * (h / 2 - 0))
                    points.push({
                        x: 0,
                        y: 0
                    });
                if (0 < -p - Math.sin(b) * (-w / 2 + 0) - Math.cos(b) * (h / 2 - h))
                    points.push({
                        x: 0,
                        y: h
                    });
                if (0 < -p - Math.sin(b) * (-w / 2 + w) - Math.cos(b) * (h / 2 - h))
                    points.push({
                        x: w,
                        y: h
                    });
                if (0 < -p - Math.sin(b) * (-w / 2 + w) - Math.cos(b) * (h / 2 - 0))
                    points.push({
                        x: w,
                        y: 0
                    });
            }

            points.push({
                x: horizon.x2,
                y: horizon.y2
            });

            ctx.save();
            ctx.strokeStyle = fg;
            ctx.lineWidth = 2 * s;
            ctx.fillStyle = isSky ? sky : ground;

            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            for (var i = 1; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y);
            }
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            ctx.restore();
        }
    }
}
