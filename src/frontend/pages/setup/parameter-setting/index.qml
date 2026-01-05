import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Styles 1.0

ColumnLayout {
    id: parameterSettingRoot
    anchors.fill: parent

    // 파라미터별 set 성공/실패 여부 저장
    property var itemStates: ({})

    Text {
        text: "파라미터 설정"
        color: Colors.textPrimary
        font.pixelSize: 24
        font.bold: true
        Layout.bottomMargin: 20
    }

    // 헤더
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 8
        color: Colors.backgroundTertiary
        z: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 20

            Text {
                text: "Name"
                Layout.leftMargin: 10
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: 16
                color: Colors.textPrimary
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Value"
                Layout.preferredWidth: 150
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 16
                color: Colors.textPrimary
            }

            Text {
                text: "Set"
                Layout.preferredWidth: 80
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 16
                color: Colors.textPrimary
            }

            Text {
                text: "Status"
                Layout.preferredWidth: 100
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 16
                color: Colors.textPrimary
            }
        }
    }

    // 트리뷰
    TreeView {
        id: treeView
        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true

        model: yourTreeModel

        delegate: TreeViewDelegate {
            id: treeDelegate
            implicitHeight: 50
            implicitWidth: treeView.width

            property int itemId: treeDelegate.model && treeDelegate.model.display ? (treeDelegate.model.display.itemId || -1) : -1
            property bool valueSetSuccess: itemId !== -1 ? (parameterSettingRoot.itemStates[itemId] ? parameterSettingRoot.itemStates[itemId].success : false) : false
            property bool hasSetValue: itemId !== -1 ? (parameterSettingRoot.itemStates[itemId] ? parameterSettingRoot.itemStates[itemId].hasSet : false) : false

            // 커스텀 indicator
            // 기본은 Material Design 아이콘 사용되서 보기 좋지 않음
            indicator: Image {
                source: treeDelegate.expanded ? resourceManager.getUrl("assets/icons/treeview/keyboard_arrow_down.svg") : resourceManager.getUrl("assets/icons/treeview/keyboard_arrow_right.svg")
                width: 16
                height: 16
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
                x: 10 + (treeDelegate.depth * 20)
                z: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        treeView.toggleExpanded(treeDelegate.row);
                    }
                }
            }

            contentItem: Rectangle {
                anchors.fill: parent
                color: Colors.backgroundSecondary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: treeDelegate.indicator.width + treeDelegate.depth * 20 + 15
                    spacing: 20

                    Text {
                        text: treeDelegate.model ? (treeDelegate.model.display.name || "") : ""
                        elide: Text.ElideRight
                        color: Colors.textPrimary
                        font.pixelSize: 16

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // TreeView의 toggleExpanded 메서드를 사용하여 실제로 확장/축소
                                treeView.toggleExpanded(treeDelegate.row);
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 20
                        visible: treeDelegate.model.display.visible

                        TextField {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 40
                            font.pixelSize: 16

                            property var itemModel: treeDelegate.model
                            property int itemId: itemModel && itemModel.display ? (itemModel.display.itemId || -1) : -1

                            // itemId property가 변경될 때 값을 업데이트
                            onItemIdChanged: {
                                if (itemId !== -1) {
                                    console.log("===========TextField itemId changed==========");
                                    console.log("New itemId:", itemId);

                                    var currentValue = yourTreeModel.getValueById(itemId);
                                    console.log("Value for ID", itemId, ":", currentValue);
                                    if (currentValue !== null && currentValue !== undefined) {
                                        text = currentValue.toString();
                                    }
                                }
                            }

                            onTextChanged: {
                                if (itemId !== -1) {
                                    // 실수 유효성 검사
                                    var numValue = parseFloat(text);
                                    if (!isNaN(numValue)) {
                                        console.log("Value changed to:", numValue, "for item ID:", itemId);
                                        // ID로 값 업데이트
                                        yourTreeModel.updateValueById(itemId, numValue);
                                    }
                                }
                            }

                            // 실수만 입력할 수 있도록 제한
                            validator: DoubleValidator {
                                bottom: -999999.0
                                top: 999999.0
                                decimals: 6
                            }
                        }

                        Button {
                            text: "Set"
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 50
                            font.pixelSize: 14
                            property var itemModel: treeDelegate.model

                            background: Rectangle {
                                color: mouseArea.containsMouse ? Qt.darker(Colors.green, 1.05) : Colors.green
                                radius: 8
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    console.log("Button clicked");
                                    if (treeDelegate.model && treeDelegate.model.display) {
                                        console.log("Model data:", treeDelegate.model.display.name);
                                        console.log("Edit value:", treeDelegate.model.display.value);
                                        console.log("Item ID:", treeDelegate.model.display.itemId);

                                        var res = yourTreeModel.getValueById(treeDelegate.model.display.itemId);
                                        console.log("Get value by ID result:", res);

                                        // 실제 설정 로직 후 상태 업데이트
                                        var itemId = treeDelegate.model.display.itemId;
                                        if (!parameterSettingRoot.itemStates[itemId]) {
                                            parameterSettingRoot.itemStates[itemId] = {};
                                        }
                                        parameterSettingRoot.itemStates[itemId].hasSet = true;
                                        parameterSettingRoot.itemStates[itemId].success = Math.random() < 0.5 ? true : false;

                                        // 상태 변경을 알리기 위해 itemStates 객체를 다시 할당
                                        // 이렇게 해야 재렌더링됨
                                        parameterSettingRoot.itemStates = Object.assign({}, parameterSettingRoot.itemStates);
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: 100
                            Layout.fillHeight: true

                            Row {
                                spacing: 2
                                anchors.centerIn: parent
                                visible: treeDelegate.hasSetValue

                                Image {
                                    source: treeDelegate.valueSetSuccess ? resourceManager.getUrl("assets/icons/serial/check_circle.svg") : resourceManager.getUrl("assets/icons/serial/block.svg")
                                    sourceSize.width: 16
                                    sourceSize.height: 16
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: treeDelegate.valueSetSuccess ? "Success" : "Fail"
                                    color: treeDelegate.valueSetSuccess ? Colors.green : Colors.red
                                    font.pixelSize: 16
                                    font.weight: 500
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
