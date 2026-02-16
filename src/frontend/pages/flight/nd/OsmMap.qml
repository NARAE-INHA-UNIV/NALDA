import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtLocation 5.15
import QtPositioning 5.15
import Qt5Compat.GraphicalEffects

Map {
    id: map
    anchors.fill: parent
    anchors.margins: 0
    layer.enabled: true
    layer.smooth: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: map.width
            height: map.height
            radius: 8
        }
    }
    plugin: Plugin {
        name: "osm"
        PluginParameter {
            name: "osm.useragent"
            value: "NALDA"
        }
        PluginParameter {
            name: "osm.mapping.providersrepository.disabled"
            value: true
        }
        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.thunderforest.com/cycle/%z/%x/%y.png?apikey=" + gpsManager.getOSMApiKey()
        }
        // PluginParameter {
        //     name: "osm.mapping.custom.datacopyright"
        //     value: "© Thunderforest, © OpenStreetMap contributors"
        // }
    }
    activeMapType: supportedMapTypes.length > 0 ? supportedMapTypes[supportedMapTypes.length - 1] : supportedMapTypes[0]
    center: QtPositioning.coordinate(37.450767, 126.657016) // 초기 위치: 인하대
    zoomLevel: 17

    // 줌 레벨 제한
    minimumZoomLevel: 1
    maximumZoomLevel: 20

    // 마우스 드래그, 휠 스크롤, 핀치 줌 지원
    // https://doc.qt.io/qt-6/qml-qtlocation-map.html#example-usage
    PinchHandler {
        id: pinch
        target: null
        onActiveChanged: if (active) {
            map.startCentroid = map.toCoordinate(pinch.centroid.position, false);
        }
        onScaleChanged: delta => {
            map.zoomLevel += Math.log2(delta);
            map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position);
        }
        onRotationChanged: delta => {
            map.bearing -= delta;
            map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position);
        }
        grabPermissions: PointerHandler.TakeOverForbidden
    }

    WheelHandler {
        id: wheel
        // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
        // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
        // and we don't yet distinguish mice and trackpads on Wayland either
        acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland" ? PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
        rotationScale: 1 / 120
        property: "zoomLevel"
    }

    DragHandler {
        id: drag
        target: null
        onTranslationChanged: delta => map.pan(-delta.x, -delta.y)
    }

    Shortcut {
        enabled: map.zoomLevel < map.maximumZoomLevel
        sequence: StandardKey.ZoomIn
        onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
    }

    Shortcut {
        enabled: map.zoomLevel > map.minimumZoomLevel
        sequence: StandardKey.ZoomOut
        onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
    }
}
