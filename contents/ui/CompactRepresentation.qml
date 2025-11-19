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
import "../code/portfolio-model.js" as PortfolioModel

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
            
            Layout.minimumWidth: 140
            Layout.minimumHeight: 40
            Layout.fillWidth: !vertical
            Layout.fillHeight: vertical

            RowLayout {
                anchors.fill: parent
                spacing: Math.max(5, parent.width * 0.02)

                Kirigami.Icon {
                    id: defaultIcon
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    source: "office-chart-line-stacked" // Stock chart icon
                    name: "view-investment"
                    fallback: true
                    Layout.preferredWidth: Math.min(parent.height - 8, Math.max(16, defaultFontPixelSize * 1.5))
                    Layout.preferredHeight: Math.min(parent.height - 8, Math.max(16, defaultFontPixelSize * 1.5))
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    PlasmaComponents.Label {
                        text: main.currentPortfolio.name || "Portfolio"
                        font.pixelSize: Math.max(10, Math.min(defaultFontPixelSize, parent.height * 0.4))
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Added P/L Summary
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: main.currentPortfolio.totalValue > 0

                        PlasmaComponents.Label {
                            text: PortfolioModel.formatCurrency(main.currentPortfolio.totalValue, main.currentPortfolio.currency)
                            font.pixelSize: Math.max(9, defaultFontPixelSize * 0.85)
                            color: Kirigami.Theme.disabledTextColor
                        }

                        PlasmaComponents.Label {
                            text: (main.currentPortfolio.dayChangePercent >= 0 ? "+" : "") + 
                                  main.currentPortfolio.dayChangePercent.toFixed(2) + "%"
                            font.pixelSize: Math.max(9, defaultFontPixelSize * 0.85)
                            color: main.currentPortfolio.dayChangePercent >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                            font.bold: true
                        }
                    }
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
                spacing: Math.max(2, parent.height * 0.02)

                Kirigami.Icon {
                    source: "wallet-closed"
                    name: "view-investment"
                    fallback: true
                    Layout.preferredWidth: Math.min(parent.width - 8, Math.max(16, defaultFontPixelSize * 1.2))
                    Layout.preferredHeight: Math.min(parent.width - 8, Math.max(16, defaultFontPixelSize * 1.2))
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                }

                PlasmaComponents.Label {
                    text: main.currentPortfolio.name || "Portfolio"
                    font.pixelSize: Math.max(8, Math.min(defaultFontPixelSize * 0.9, parent.width * 0.15))
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.bold: true
                }

                // Added P/L Summary for vertical layout
                PlasmaComponents.Label {
                    text: (main.currentPortfolio.dayChangePercent >= 0 ? "+" : "") + 
                          main.currentPortfolio.dayChangePercent.toFixed(2) + "%"
                    font.pixelSize: Math.max(8, defaultFontPixelSize * 0.8)
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: main.currentPortfolio.dayChangePercent >= 0 ? 
                           Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                    visible: main.currentPortfolio.totalValue > 0
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
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true

        // Hover effect background
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.highlightColor
            opacity: mouseArea.containsMouse ? 0.1 : 0
            visible: mouseArea.containsMouse
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

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
