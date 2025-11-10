/*
 * StockTea - Compact Representation
 * Shows portfolio summary in panel/tray
 */
import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Loader {
    id: compactRepresentation

    anchors.fill: parent

    readonly property bool vertical: (main.vertical)

    property int defaultWidgetSize: -1
    property int widgetOrder: main.widgetOrder
    property int layoutType: main.layoutType || 0

    sourceComponent: layoutType === 2 ? compactItem : widgetOrder === 1 ? compactItemReverse : compactItem

    Layout.fillWidth: compactRepresentation.vertical
    Layout.fillHeight: !compactRepresentation.vertical
    Layout.minimumWidth: item ? item.Layout.minimumWidth : 100
    Layout.minimumHeight: item ? item.Layout.minimumHeight : 50

    // Define compactItem inline
    Component {
        id: compactItem
        Item {
            property bool vertical: false
            
            property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
            
            Layout.minimumWidth: 120
            Layout.minimumHeight: 40
            Layout.fillWidth: !vertical
            Layout.fillHeight: vertical

            RowLayout {
                anchors.fill: parent
                spacing: Math.max(5, parent.width * 0.02)

                Kirigami.Icon {
                    source: "./piggy-bank-icon.svg"
                    Layout.preferredWidth: Math.min(parent.height - 8, Math.max(16, defaultFontPixelSize * 1.2))
                    Layout.preferredHeight: Math.min(parent.height - 8, Math.max(16, defaultFontPixelSize * 1.2))
                    Layout.alignment: Qt.AlignVCenter
                }

                PlasmaComponents.Label {
                    text: main.currentPortfolio.name || "Portfolio"
                    font.pixelSize: Math.max(10, Math.min(defaultFontPixelSize * 0.9, parent.height * 0.4))
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Define compactItemReverse inline
    Component {
        id: compactItemReverse
        Item {
            property bool vertical: false
            
            property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
            
            Layout.minimumWidth: 80
            Layout.minimumHeight: 60
            Layout.fillWidth: !vertical
            Layout.fillHeight: vertical

            ColumnLayout {
                anchors.fill: parent
                spacing: Math.max(3, parent.height * 0.02)

                Kirigami.Icon {
                    source: "./piggy-bank-icon.svg"
                    Layout.preferredWidth: Math.min(parent.width - 8, Math.max(16, defaultFontPixelSize))
                    Layout.preferredHeight: Math.min(parent.width - 8, Math.max(16, defaultFontPixelSize))
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                }

                PlasmaComponents.Label {
                    text: main.currentPortfolio.name || "Portfolio"
                    font.pixelSize: Math.max(8, Math.min(defaultFontPixelSize * 0.8, parent.width * 0.15))
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }

    PlasmaComponents.BusyIndicator {
        id: busyIndicator
        anchors.fill: parent
        visible: false
        running: false

        states: [
            State {
                name: 'loading'
                when: !loadingDataComplete

                PropertyChanges {
                    target: busyIndicator
                    visible: true
                    running: true
                }

                PropertyChanges {
                    target: compactItem
                }
            }
        ]
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        hoverEnabled: true

        onClicked: (mouse)=> {
            if (mouse.button === Qt.MiddleButton) {
                loadingData.failedAttemptCount = 0
                main.loadDataFromInternet()
            } else {
                main.expanded = !main.expanded
            }
        }

        onEntered: main.refreshTooltipSubText()

        PlasmaCore.ToolTipArea {
            id: toolTipArea
            anchors.fill: parent
            active: !main.expanded
            interactive: true
            mainText: main.currentPortfolio.name
            subText: main.toolTipSubText
            textFormat: Text.RichText
        }
    }

    Component.onCompleted: {
        if ((defaultWidgetSize === -1) && (compactRepresentation.width > 0 || compactRepresentation.height)) {
            defaultWidgetSize = Math.min(compactRepresentation.width, compactRepresentation.height)
        }
    }
}