import QtQuick
import QtQuick3D

Node {
    id: node

    // Properties for external control of rotation angles
    property real rollAngle: 0
    property real pitchAngle: 0
    property real yawAngle: 0

    property var motorThrust: [0, 0, 0, 0]

    property bool showHelperAxes: true
    property bool showThrust: true

    // Apply rotation based on input angles
    eulerRotation: Qt.vector3d(-pitchAngle, -yawAngle, rollAngle)

    // 드론 모델 재질 개선
    PrincipledMaterial {
        id: mavicMaterial
        objectName: "mavic"
        baseColor: "#999"
        roughness: 0.4
        metalness: 0.2
        alphaMode: PrincipledMaterial.Opaque
        indexOfRefraction: 1
        emissiveFactor: Qt.vector3d(0.2, 0.2, 0.2)
    }

    // Materials for axes
    PrincipledMaterial {
        id: rollAxisMaterial
        baseColor: "#ff0000"
        roughness: 0.1
        metalness: 0.0
        emissiveFactor: Qt.vector3d(0.6, 0.0, 0.0)
    }

    PrincipledMaterial {
        id: pitchAxisMaterial
        baseColor: "#00ff00"
        roughness: 0.1
        metalness: 0.0
        emissiveFactor: Qt.vector3d(0.0, 0.6, 0.0)
    }

    PrincipledMaterial {
        id: yawAxisMaterial
        baseColor: "#0000ff"
        roughness: 0.1
        metalness: 0.0
        emissiveFactor: Qt.vector3d(0.0, 0.0, 0.6)
    }

    // roll axis
    Model {
        id: rollAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        eulerRotation.x: 90
        materials: [rollAxisMaterial]
        visible: showHelperAxes
    }

    // pitch axis
    Model {
        id: pitchAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        eulerRotation.z: 90
        materials: [pitchAxisMaterial]
        visible: showHelperAxes
    }

    // yaw axis
    Model {
        id: yawAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        materials: [yawAxisMaterial]
        visible: showHelperAxes
    }

    // motor thrust vectors
    TrustVector {
        id: frontRightMotorThrust
        showThrust: node.showThrust
        thrustValue: motorThrustScaler(node.motorThrust[0])
        posX: 61.5
        posZ: 35.5
    }

    TrustVector {
        id: frontLeftMotorThrust
        showThrust: node.showThrust
        thrustValue: motorThrustScaler(node.motorThrust[1])
        posX: -61.5
        posZ: 35.5
    }

    TrustVector {
        id: rearLeftMotorThrust
        showThrust: node.showThrust
        thrustValue: motorThrustScaler(node.motorThrust[2])
        posX: 46
        posZ: -55.5
    }

    TrustVector {
        id: rearRightMotorThrust
        showThrust: node.showThrust
        thrustValue: motorThrustScaler(node.motorThrust[3])
        posX: -46
        posZ: -55.5
    }

    // 드론 3D 모델
    Model {
        id: mavic
        objectName: "mavic"
        source: resourceManager.getUrl("assets/meshes/mavic.mesh")
        scale: Qt.vector3d(30, 30, 30)
        position: Qt.vector3d(0, -30, 12)
        materials: [mavicMaterial]
    }

    function motorThrustScaler(value) {
        // 1000~2000 to 0.0~1.0
        if (value < 1000)
            return 0.0;
        if (value > 2000)
            return 1.0;
        return (value - 1000) / 1000.0;
    }
}
