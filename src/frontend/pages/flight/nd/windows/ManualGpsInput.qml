import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: manualGpsRoot
    color: "#1a1a1a"
    radius: 8

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "[테스트용] Manual GPS Input"
            color: "white"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            Label { text: "Lat:"; color: "white" }
            TextField { id: latInput; Layout.fillWidth: true; placeholderText: "Latitude"; validator: DoubleValidator{} }
            Label { text: "Lon:"; color: "white" }
            TextField { id: lonInput; Layout.fillWidth: true; placeholderText: "Longitude"; validator: DoubleValidator{} }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 5  
            Label { text: "Alt:"; color: "white" }
            TextField { id: altInput; Layout.fillWidth: true; placeholderText: "Altitude"; validator: DoubleValidator{} }
            Label { text: "Hdg:"; color: "white" }
            TextField { id: hdgInput; Layout.fillWidth: true; placeholderText: "Heading"; validator: DoubleValidator{} }
        }
        Button {
            Layout.fillWidth: true
            text: "Update GPS Manually"
            onClicked: {
                if (latInput.text && lonInput.text && altInput.text && hdgInput.text) {
                    gpsManager.updateGpsManual(
                        parseFloat(latInput.text),
                        parseFloat(lonInput.text),
                        parseFloat(altInput.text),
                        parseFloat(hdgInput.text)
                    );
                } else {
                    console.log("Please fill all GPS fields.");
                }
            }
        }
    }
}
