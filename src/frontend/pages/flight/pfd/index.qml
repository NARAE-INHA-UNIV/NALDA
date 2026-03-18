import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import Colors 1.0

Rectangle {
    id: pfdRoot
    anchors.fill: parent
    color: Colors.backgroundPrimary

    Connections {
        target: pfdManager

        function onPitchAngleChanged(v)  { pfd.pitch       = v }
        function onRollAngleChanged(v)   { pfd.roll        = v }
        function onAltitudeChanged(v)    { pfd.alt         = v }
        function onAirspeedChanged(v)    { pfd.airspeed    = v }
        function onGroundspeedChanged(v) { pfd.groundspeed = v }
        function onHeadingChanged(v)     { pfd.heading     = v }
        function onVspdChanged(v)        { pfd.vspeed      = v }
        function onFixTypeChanged(v)     { pfd.fix_type    = v }
    }

    PrimaryFlightDisplay {
        id: pfd
        anchors.fill: parent

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: pfdRoot.width
                height: pfdRoot.height
                radius: 12
            }
        }

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
