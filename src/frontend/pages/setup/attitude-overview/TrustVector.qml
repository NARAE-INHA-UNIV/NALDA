import QtQuick
import QtQuick3D

Node {
    id: node

    property real posX: 0
    property real posZ: 0
    property real thrustValue: 1.0
    property real thrustScale: 1.0

    property bool showThrust: true

    PrincipledMaterial {
        id: motorThrustMaterial
        baseColor: "yellow"
        roughness: 0.1
        metalness: 0.0
        emissiveFactor: Qt.vector3d(0.6, 0.6, 0.0)
    }

    // motor thrust
    Model {
        id: frontRightMotorThrust
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, node.thrustValue * node.thrustScale, 0.01)
        position: Qt.vector3d(node.posX, (node.thrustValue * node.thrustScale / 2) * 100, node.posZ)
        materials: [motorThrustMaterial]
        visible: node.showThrust
    }

    // thrust arrow cone
    Model {
        id: thrustCone
        source: "#Cone"
        scale: Qt.vector3d(0.02, 0.05, 0.02)
        position: Qt.vector3d(node.posX, (node.thrustValue * node.thrustScale) * 100, node.posZ)
        materials: [motorThrustMaterial]
        visible: node.showThrust
    }
}
