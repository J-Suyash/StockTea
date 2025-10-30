/*
 * StockTea - Portfolio View
 * Displays portfolio positions and summary
 *
 * Copyright 2024 StockTea
 * This program is free software; you can redistribute it and/or modify
 * it under terms of the GNU General Public License as published by
 * Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
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
    anchors.fill: parent
    
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize

    ColumnLayout {
        id: mainColumn
        width: scrollView.width
        spacing: 15

        // Portfolio Summary Card
        Rectangle {
            id: summaryCard
            Layout.fillWidth: true
            Layout.preferredHeight: summaryColumn.height + 20
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ColumnLayout {
                id: summaryColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Portfolio Summary")
                        font.pixelSize: defaultFontPixelSize * 1.1
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    PlasmaComponents.Label {
                        text: main.currentPortfolio.currency || "USD"
                        font.pixelSize: defaultFontPixelSize * 0.9
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 5

                    PlasmaComponents.Label {
                        text: i18n("Total Value:")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.disabledTextColor
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.totalValue, main.currentPortfolio.currency)
                        font.pixelSize: defaultFontPixelSize
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }

                    PlasmaComponents.Label {
                        text: i18n("Total Cost:")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.disabledTextColor
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.totalCost, main.currentPortfolio.currency)
                        font.pixelSize: defaultFontPixelSize
                        Layout.alignment: Qt.AlignRight
                    }

                    PlasmaComponents.Label {
                        text: i18n("Total P/L:")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.disabledTextColor
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.totalProfitLoss, main.currentPortfolio.currency) + 
                              " (" + PortfolioModel.formatPercent(main.currentPortfolio.totalProfitLossPercent) + ")"
                        font.pixelSize: defaultFontPixelSize
                        font.bold: true
                        color: main.currentPortfolio.totalProfitLoss >= 0 ? 
                               Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        Layout.alignment: Qt.AlignRight
                    }

                    PlasmaComponents.Label {
                        text: i18n("Day Change:")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.disabledTextColor
                    }
                    PlasmaComponents.Label {
                        text: PortfolioModel.formatCurrency(main.currentPortfolio.dayChange, main.currentPortfolio.currency) + 
                              " (" + PortfolioModel.formatPercent(main.currentPortfolio.dayChangePercent) + ")"
                        font.pixelSize: defaultFontPixelSize
                        color: main.currentPortfolio.dayChange >= 0 ? 
                               Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }

        // Positions Header
        PlasmaComponents.Label {
            text: i18n("Positions (%1)", main.positionsModel.count)
            font.pixelSize: defaultFontPixelSize * 1.1
            font.bold: true
            Layout.fillWidth: true
        }

        // Positions List
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(positionsListView.contentHeight + 20, 300)
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ListView {
                id: positionsListView
                anchors.fill: parent
                anchors.margins: 10
                model: main.positionsModel
                spacing: 5

                delegate: PositionItem {
                    width: positionsListView.width
                    position: model
                }

                // Empty state
                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: i18n("No positions in this portfolio")
                    font.pixelSize: defaultFontPixelSize
                    color: Kirigami.Theme.disabledTextColor
                    visible: main.positionsModel.count === 0
                }
            }
        }

        // Add some bottom spacing
        Item {
            Layout.preferredHeight: 20
        }
    }
}