/*
 * StockTea - Portfolio View
 * Displays portfolio positions and summary
 *
 */
import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import QtQuick.Controls
import "../code/portfolio-model.js" as PortfolioModel

ScrollView {
    id: scrollView
    
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 400

    ColumnLayout {
        id: mainColumn
        width: scrollView.width
        spacing: 15

        // Portfolio Summary Card
        Rectangle {
            id: summaryCard
            Layout.fillWidth: true
            Layout.preferredHeight: summaryColumn.height + 30
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            // Subtle background gradient for premium feel
            Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.lighter(Kirigami.Theme.backgroundColor, 1.05) }
                GradientStop { position: 1.0; color: Kirigami.Theme.backgroundColor }
            }

            ColumnLayout {
                id: summaryColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 15
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Portfolio Summary")
                        font.pixelSize: defaultFontPixelSize * 1.2
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignRight
                        
                        PlasmaComponents.Label {
                            text: main.currentPortfolio.currency || "INR"
                            font.pixelSize: defaultFontPixelSize * 0.8
                            color: Kirigami.Theme.disabledTextColor
                            Layout.alignment: Qt.AlignRight
                        }
                        
                        PlasmaComponents.Label {
                            text: PortfolioModel.getLastUpdateTimeText(main.currentPortfolio.lastUpdate)
                            font.pixelSize: defaultFontPixelSize * 0.7
                            color: Kirigami.Theme.disabledTextColor
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Kirigami.Theme.disabledTextColor
                    opacity: 0.3
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 8

                    // Total Value (Prominent)
                    PlasmaComponents.Label {
                        text: i18n("Total Value")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.textColor
                        Layout.alignment: Qt.AlignLeft
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.totalValue, main.currentPortfolio.currency)
                        font.pixelSize: defaultFontPixelSize * 1.5
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }

                    // Total Cost
                    PlasmaComponents.Label {
                        text: i18n("Invested Amount")
                        font.pixelSize: defaultFontPixelSize * 0.9
                        color: Kirigami.Theme.disabledTextColor
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.totalCost, main.currentPortfolio.currency)
                        font.pixelSize: defaultFontPixelSize * 0.9
                        color: Kirigami.Theme.disabledTextColor
                        Layout.alignment: Qt.AlignRight
                    }

                    // Separator
                    Item { Layout.columnSpan: 2; height: 5; width: 1 }

                    // Total P/L
                    PlasmaComponents.Label {
                        text: i18n("Total P/L")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.textColor
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 5
                        
                        PlasmaComponents.Label {
                            text: PortfolioModel.formatCurrency(main.currentPortfolio.totalProfitLoss, main.currentPortfolio.currency)
                            font.pixelSize: defaultFontPixelSize
                            font.bold: true
                            color: main.currentPortfolio.totalProfitLoss >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                        
                        Rectangle {
                            width: plPercentLabel.width + 8
                            height: plPercentLabel.height + 4
                            radius: 4
                            color: (main.currentPortfolio.totalProfitLoss >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor)
                            opacity: 0.15
                            
                            PlasmaComponents.Label {
                                id: plPercentLabel
                                anchors.centerIn: parent
                                text: PortfolioModel.formatPercent(main.currentPortfolio.totalProfitLossPercent)
                                font.pixelSize: defaultFontPixelSize * 0.85
                                font.bold: true
                                color: main.currentPortfolio.totalProfitLoss >= 0 ? 
                                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                            }
                        }
                    }

                    // Day Change
                    PlasmaComponents.Label {
                        text: i18n("Day Change")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.textColor
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 5
                        
                        PlasmaComponents.Label {
                            text: PortfolioModel.formatCurrency(main.currentPortfolio.dayChange, main.currentPortfolio.currency)
                            font.pixelSize: defaultFontPixelSize
                            font.bold: true
                            color: main.currentPortfolio.dayChange >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                        
                        Rectangle {
                            width: dayPercentLabel.width + 8
                            height: dayPercentLabel.height + 4
                            radius: 4
                            color: (main.currentPortfolio.dayChange >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor)
                            opacity: 0.15
                            
                            PlasmaComponents.Label {
                                id: dayPercentLabel
                                anchors.centerIn: parent
                                text: PortfolioModel.formatPercent(main.currentPortfolio.dayChangePercent)
                                font.pixelSize: defaultFontPixelSize * 0.85
                                font.bold: true
                                color: main.currentPortfolio.dayChange >= 0 ? 
                                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                            }
                        }
                    }
                }
            }
        }

        // Positions Header
        PlasmaComponents.Label {
            text: i18n("Positions (%1)", main.positionsList ? main.positionsList.count : 0)
            font.pixelSize: defaultFontPixelSize * 1.1
            font.bold: true
            Layout.fillWidth: true
        }

        // Positions List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            Layout.preferredHeight: Math.max(200, positionsListView.contentHeight + 20)
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ListView {
                id: positionsListView
                anchors.fill: parent
                anchors.margins: 10
                model: main.positionsList
                spacing: 5
                clip: true

                delegate: PositionItem {
                    width: positionsListView.width
                    position: model
                }

                // Empty state
                Item {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: parent.height * 0.8
                    visible: !main.positionsList || main.positionsList.count === 0
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 15
                        
                        Kirigami.Icon {
                            source: "wallet-open"
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 64
                            Layout.alignment: Qt.AlignHCenter
                            opacity: 0.5
                        }
                        
                        PlasmaComponents.Label {
                            text: i18n("Your portfolio is empty")
                            font.pixelSize: defaultFontPixelSize * 1.2
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                            opacity: 0.7
                        }
                        
                        PlasmaComponents.Label {
                            text: i18n("Go to the Manage tab to add stocks to your portfolio.")
                            font.pixelSize: defaultFontPixelSize
                            color: Kirigami.Theme.disabledTextColor
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.maximumWidth: 250
                        }
                        
                        PlasmaComponents.Button {
                            text: i18n("Add Position")
                            icon.name: "list-add"
                            Layout.alignment: Qt.AlignHCenter
                            onClicked: {
                                main.mainTabBar.currentIndex = 2 // Switch to Manage tab
                            }
                        }
                    }
                }
            }
        }

        // Add some bottom spacing
        Item {
            Layout.preferredHeight: 20
        }
    }
}