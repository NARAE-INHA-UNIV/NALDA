import QtQuick 2.15
import QtQuick.Dialogs
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform

ApplicationWindow {
    id: algorithmInputPanel
    title: "경로 계획 알고리즘 추가"
    width: 600
    height: 500
    visible: true
    color: "#2a2a2a"
    
    property url selectedFileUrl: ""
    
    signal accepted(string algorithmName, url fileUrl)
    signal cancelled()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 알고리즘 이름 입력
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text {
                text: "알고리즘 이름:"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
            
            TextField {
                id: newAlgorithmName
                Layout.fillWidth: true
                placeholderText: "알고리즘 이름을 입력하세요"
                color: "white"
                background: Rectangle {
                    color: "#4a4a4a"
                    border.color: "#666666"
                    border.width: 1
                    radius: 5
                }
            }
        }
        
        // 파일 선택
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text {
                text: "경로 파일 (.txt, .csv):"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "파일 선택"
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 30
                    
                    background: Rectangle {
                        color: parent.pressed ? "#616161" : "#757575"
                        radius: 4
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }
                    
                    onClicked: {
                        console.log("File selection button clicked")
                        // Try platform file dialog first, fallback to regular FileDialog
                        if (platformFileDialog.available) {
                            console.log("Using platform file dialog")
                            platformFileDialog.open()
                        } else {
                            console.log("Using regular file dialog")
                            fileDialog.open()
                        }
                    }
                }
                
                Column {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Text {
                        id: fileUrlText
                        width: parent.width
                        text: "파일이 선택되지 않았습니다"
                        color: "#cccccc"
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                    }
                    
                    Text {
                        id: fullPathText
                        width: parent.width
                        text: ""
                        color: "#999999"
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        visible: text !== ""
                    }
                }
            }
        }
        
        // 버튼 영역
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 10
            
            Button {
                text: "취소"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: parent.pressed ? "#616161" : "#757575"
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                }
                
                onClicked: {
                    cancelled()
                    close()
                }
            }
            
            Button {
                text: "추가"
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: parent.pressed ? "#388E3C" : "#4CAF50"
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                }
                
                onClicked: {
                    console.log("Add button clicked")
                    console.log("Algorithm name:", newAlgorithmName.text.trim())
                    console.log("Selected File URL:", algorithmInputPanel.selectedFileUrl)
                    console.log("Selected File URL type:", typeof algorithmInputPanel.selectedFileUrl)
                    console.log("Selected File URL string:", algorithmInputPanel.selectedFileUrl.toString())
                    
                    var algorithmName = newAlgorithmName.text.trim()
                    var hasValidName = algorithmName !== ""
                    var hasValidFile = algorithmInputPanel.selectedFileUrl && algorithmInputPanel.selectedFileUrl.toString() !== ""
                    
                    if (hasValidName && hasValidFile) {
                        console.log("Validation passed - calling accepted signal")
                        accepted(algorithmName, algorithmInputPanel.selectedFileUrl)
                        close()
                    } else {
                        var errorMsg = ""
                        if (!hasValidName) errorMsg += "알고리즘 이름을 입력해주세요. "
                        if (!hasValidFile) errorMsg += "파일을 선택해주세요."
                        
                        console.log("Validation failed:", errorMsg)
                        console.log("알고리즘 이름과 파일을 모두 선택해주세요.")
                    }
                }
            }
        }
    }
    
    // Platform FileDialog (preferred for macOS)
    Platform.FileDialog {
        id: platformFileDialog
        title: "경로 파일 선택"
        nameFilters: ["Text files (*.txt)", "CSV files (*.csv)", "All files (*)"]
        fileMode: Platform.FileDialog.OpenFile
        folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
        
        property bool available: true
        
        onAccepted: {
            console.log("Platform FileDialog accepted - file:", platformFileDialog.file)
            handleFileSelection(platformFileDialog.file)
        }
        
        onRejected: {
            console.log("Platform FileDialog rejected")
        }
    }
    
    // Fallback FileDialog
    FileDialog {
        id: fileDialog
        title: "경로 파일 선택"
        nameFilters: ["Text files (*.txt)", "CSV files (*.csv)", "All files (*)"]
        fileMode: FileDialog.OpenFile
        
        onAccepted: {
            console.log("FileDialog accepted - fileUrl:", fileDialog.fileUrl)
            console.log("FileDialog selectedFile:", fileDialog.selectedFile)
            handleFileSelection(fileDialog.fileUrl)
        }
        
        onRejected: {
            console.log("FileDialog rejected")
        }
    }
    
    // Common file selection handler
    function handleFileSelection(fileUrl) {
        console.log("Handling file selection:", fileUrl)
        
        if (fileUrl && fileUrl.toString() !== "") {
            var fileName = fileUrl.toString()
            console.log("Full file path:", fileName)
            
            // 파일 경로에서 파일명만 추출
            var fileNameOnly = fileName.split('/').pop()
            // Remove file:// prefix if present
            if (fileNameOnly.startsWith('file://')) {
                fileNameOnly = fileNameOnly.substring(7)
            }
            
            fileUrlText.text = "선택된 파일: " + fileNameOnly
            fileUrlText.color = "#4CAF50"
            fullPathText.text = "전체 경로: " + fileName
            
            // Store the selected file URL for validation
            algorithmInputPanel.selectedFileUrl = fileUrl
            
            console.log("File selected successfully:", fileNameOnly)
        } else {
            console.log("File URL is empty or undefined")
            fileUrlText.text = "파일 선택 실패"
            fileUrlText.color = "#f44336"
            fullPathText.text = ""
            algorithmInputPanel.selectedFileUrl = ""
        }
    }
}
