import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: pfdRoot
    anchors.fill: parent

    Connections {
        target: serialManager

        function onMessageUpdated(messageId, data) {
            if (messageId === 30) {
                // ATTITUDE (30): roll, pitch, yaw
                pfd.pitch = data.pitch || 0;  // 이미 radians
                pfd.roll = data.roll || 0;    // 이미 radians
            } else if (messageId === 74) {
                // VFR_HUD (74): airspeed, groundspeed, heading, alt, climb
                pfd.airspeed = data.airspeed || 0;
                pfd.groundspeed = data.groundspeed || 0;
                pfd.heading = data.heading || 0;
                pfd.alt = data.alt || 0;
                pfd.vspeed = data.climb || 0;
            } else if (messageId === 33) {
                // GLOBAL_POSITION_INT (33): alt, vx, vy, vz
                // 고도는 mm 단위이므로 m로 변환
                if (data.alt !== undefined) {
                    pfd.alt = data.alt / 1000.0;
                }
                // 수직 속도는 cm/s 단위이므로 m/s로 변환
                if (data.vz !== undefined) {
                    pfd.vspeed = -data.vz / 100.0;  // 음수는 상승, 양수는 하강
                }
            } else if (messageId === 24) {
                // GPS_RAW_INT (24): fix_type
                pfd.fix_type = data.fix_type || 0;
            }
        }
    }

    PrimaryFlightDisplay {
        id: pfd
        anchors.fill: parent

        // 초기값
        pitch: 0
        roll: 0
        heading: 0
        airspeed: 0
        groundspeed: 0
        alt: 0
        vspeed: 0
        skipskid: 0.0
        fix_type: 0
    }
}
