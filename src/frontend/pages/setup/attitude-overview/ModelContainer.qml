import QtQuick
import QtQuick3D


View3D {
    id: modelContainer

    property real cameraDistance: 400
    property real cameraAzimuth: -30
    property real cameraElevation: 30

    property real rollAngle: 0
    property real pitchAngle: 0
    property real yawAngle: 0

    property bool showFixedAxes: true
    property bool showHelperAxes: true

    function updateCameraPosition() {
        var radAzimuth = cameraAzimuth * Math.PI / 180
        var radElevation = cameraElevation * Math.PI / 180
        
        var x = cameraDistance * Math.cos(radElevation) * Math.sin(radAzimuth)
        var y = cameraDistance * Math.sin(radElevation)
        var z = cameraDistance * Math.cos(radElevation) * Math.cos(radAzimuth)
        
        camera.position = Qt.vector3d(x, y, z)
        camera.lookAt(Qt.vector3d(0, 0, 0))
    }

    //! [environment]
    environment: SceneEnvironment {
        clearColor: "black"
        backgroundMode: SceneEnvironment.Color
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.High
    }
    //! [environment]

    //! [camera]
    PerspectiveCamera {
        id: camera
        position: Qt.vector3d(0, 200, 300)
        eulerRotation.x: -30
        
        Component.onCompleted: {
            modelContainer.updateCameraPosition()
        }
    }
    //! [camera]

    //! [light]
    // Main directional light - 더 밝게
    DirectionalLight {
        id: mainLight
        eulerRotation.x: -30
        eulerRotation.y: -70
        brightness: 1.2
    }
    
    // Additional directional lights for better coverage - 더 밝게
    DirectionalLight {
        id: fillLight1
        eulerRotation.x: 30
        eulerRotation.y: 110
        brightness: 0.8
    }
    
    DirectionalLight {
        id: fillLight2
        eulerRotation.x: 0
        eulerRotation.y: 180
        brightness: 0.6
    }
    
    // 위쪽에서 비추는 조명 추가
    DirectionalLight {
        id: topLight
        eulerRotation.x: -90
        eulerRotation.y: 0
        brightness: 0.8
    }
    
    // 아래쪽에서 비추는 조명 추가
    DirectionalLight {
        id: bottomLight
        eulerRotation.x: 90
        eulerRotation.y: 0
        brightness: 0.5
    }
    
    // 전방향 조명
    DirectionalLight {
        id: ambientLight
        eulerRotation.x: 0
        eulerRotation.y: 0
        brightness: 1.0
    }
    //! [light]

    // 고정 좌표계 재질)
    PrincipledMaterial {
        id: fixedAxisMaterial
        baseColor: "#ffffff"
        roughness: 0.1
        metalness: 0.0
        emissiveFactor: Qt.vector3d(0.8, 0.8, 0.8)
    }

    // 고정 좌표계 축들 (항상 고정된 방향, 드론과 함께 회전하지 않음)
    // X-Axis (흰색)
    Model {
        id: fixedXAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        eulerRotation.x: 90
        materials: [fixedAxisMaterial]
        visible: showFixedAxes
    }

    // Y-Axis (흰색)
    Model {
        id: fixedYAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        eulerRotation.z: 90
        materials: [fixedAxisMaterial]
        visible: showFixedAxes
    }

    // Z-Axis (흰색)
    Model {
        id: fixedZAxis
        source: "#Cylinder"
        scale: Qt.vector3d(0.01, 3, 0.01)
        position: Qt.vector3d(0, 0, 0)
        materials: [fixedAxisMaterial]
        visible: showFixedAxes
    }

    DroneModel {
        id: droneModel
        
        rollAngle: modelContainer.rollAngle
        pitchAngle: modelContainer.pitchAngle
        yawAngle: modelContainer.yawAngle

        showHelperAxes: modelContainer.showHelperAxes
    }
    //! [objects]

    // Mouse control for camera
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        property real lastMouseX: 0
        property real lastMouseY: 0
        property bool isDragging: false
        
        onPressed: function(mouse) {
            lastMouseX = mouse.x
            lastMouseY = mouse.y
            isDragging = true
        }
        
        onReleased: {
            isDragging = false
        }
        
        onPositionChanged: function(mouse) {
            if (!isDragging) return
            
            var deltaX = mouse.x - lastMouseX
            var deltaY = mouse.y - lastMouseY
            
            if (mouse.buttons & Qt.LeftButton) {
                // Orbit camera (reversed direction)
                modelContainer.cameraAzimuth -= deltaX * 0.5
                modelContainer.cameraElevation = Math.max(-89, Math.min(89, modelContainer.cameraElevation + deltaY * 0.5))
                modelContainer.updateCameraPosition()
            }
            
            lastMouseX = mouse.x
            lastMouseY = mouse.y
        }
        
        onWheel: function(wheel) {
            // Zoom with mouse wheel
            var zoomFactor = wheel.angleDelta.y > 0 ? 0.9 : 1.1
            modelContainer.cameraDistance = Math.max(50, Math.min(1000, modelContainer.cameraDistance * zoomFactor))
            modelContainer.updateCameraPosition()
        }
    }
}
