import QtQuick
import QtQuick3D

Node {
    id: node

    // Properties for external control of rotation angles
    property real rollAngle: 0
    property real pitchAngle: 0
    property real yawAngle: 0

    property bool showHelperAxes: true

    // Apply rotation based on input angles
    eulerRotation: Qt.vector3d(- pitchAngle, - yawAngle, rollAngle)

    // Resources - 드론 모델 재질 개선
    PrincipledMaterial {
        id: finalDJI_material
        objectName: "FinalDJI"
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

    // 드론 3D 도델
    Node {
        id: mavic_obj
        objectName: "mavic.obj"
        Model {
            id: wing8
            objectName: "Wing8"
            source: "meshes/wing8_mesh.mesh"
            scale: Qt.vector3d(30, 30, 30)
            position: Qt.vector3d(0, -30, 0)
            materials: [
                finalDJI_material
            ]
        }
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

    // 백엔드에서 각도 값을 설정하면 해당 각도로 즉시 회전됩니다
    // 사용법:
    // resultModel.rollAngle = 45    // X축으로 45도 회전
    // resultModel.pitchAngle = 30   // Y축으로 30도 회전  
    // resultModel.yawAngle = 90     // Z축으로 90도 회전
}
