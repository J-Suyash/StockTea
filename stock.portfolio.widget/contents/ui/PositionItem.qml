/*
 * StockTea - Position Item
 * Individual stock position display component
 *
 * Copyright 2024 StockTea
 * This program is free software; you can redistribute it and/or modify
 * it under terms of the GNU General Public License as published by
 * Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
import QtQuick 2.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import QtQuick.Controls
import "../code/portfolio-model.js" as PortfolioModel

Rectangle {
    id: positionItem
    
    property var position: ({})
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    
    width: parent.width
    height: positionColumn.height + 10
    color: Kirigami.Theme.backgroundColor
    border.color: Kirigami.Theme.disabledTextColor
    border.width: 1
    radius: 6
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onEntered: {
            parent.color = Kirigami.Theme.hoverColor
        }
        
        onExited: {
            parent.color = Kirigami.Theme.backgroundColor
        }
        
        onClicked: {
            // Load candlestick data for this position
            loadCandlestickData(position.symbol)
        }
    }
    
    ColumnLayout {
        id: positionColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 5
        
        // Header with symbol and name
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Label {
                text: position.symbol || ""
                font.pixelSize: defaultFontPixelSize * 1.1
                font.bold: true
                Layout.fillWidth: true
            }
            
            PlasmaComponents.Label {
                text: position.name || position.symbol || ""
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignRight
            }
        }
        
        // Position details
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 15
            rowSpacing: 3
            
            // Quantity
            PlasmaComponents.Label {
                text: i18n("Qty:")
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Label {
                text: position.quantity ? position.quantity.toString() : "0"
                font.pixelSize: defaultFontPixelSize * 0.9
            }
            Item { Layout.columnSpan: 1 } // Spacer
            
            // Current Price
            PlasmaComponents.Label {
                text: i18n("Price:")
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Label {
                text: position.currentPrice ? 
                       PortfolioModel.formatCurrency(position.currentPrice, position.currency) : "--"
                font.pixelSize: defaultFontPixelSize * 0.9
                font.bold: true
            }
            Item { Layout.columnSpan: 1 } // Spacer
            
            // Day Change
            PlasmaComponents.Label {
                text: i18n("Day:")
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Label {
                text: position.dayChange !== undefined ? 
                       PortfolioModel.formatCurrency(position.dayChange, position.currency) + 
                       " (" + PortfolioModel.formatPercent(position.dayChangePercent) + ")" : "--"
                font.pixelSize: defaultFontPixelSize * 0.9
                color: position.dayChange >= 0 ? 
                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
            }
            Item { Layout.columnSpan: 1 } // Spacer
            
            // Total Value
            PlasmaComponents.Label {
                text: i18n("Value:")
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Label {
                text: position.totalValue ? 
                       PortfolioModel.formatCurrency(position.totalValue, position.currency) : "--"
                font.pixelSize: defaultFontPixelSize * 0.9
                font.bold: true
            }
            Item { Layout.columnSpan: 1 } // Spacer
            
            // P/L
            PlasmaComponents.Label {
                text: i18n("P/L:")
                font.pixelSize: defaultFontPixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            PlasmaComponents.Label {
                text: position.profitLoss !== undefined ? 
                       PortfolioModel.formatCurrency(position.profitLoss, position.currency) + 
                       " (" + PortfolioModel.formatPercent(position.profitLossPercent) + ")" : "--"
                font.pixelSize: defaultFontPixelSize * 0.9
                font.bold: true
                color: position.profitLoss >= 0 ? 
                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
            }
            Item { Layout.columnSpan: 1 } // Spacer
        }
        
        // Progress bar for P/L percentage
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            color: Kirigami.Theme.disabledTextColor
            radius: 2
            visible: position.profitLossPercent !== undefined
            
            Rectangle {
                id: profitBar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.abs(position.profitLossPercent) > 100 ? parent.width : 
                        Math.abs(position.profitLossPercent) * parent.width / 100
                color: position.profitLoss >= 0 ? 
                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                radius: 2
                
                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
    
    function loadCandlestickData(symbol) {
        dbgprint("Loading candlestick data for: " + symbol)
        
        // Switch to chart tab and load data
        var parentTabView = parent.parent.parent.parent.parent
        while (parentTabView && parentTabView.objectName !== "mainTabView") {
            parentTabView = parentTabView.parent
        }
        
        if (parentTabView) {
            parentTabView.currentIndex = 1 // Switch to chart tab
            // Emit signal to load chart data
            chartView.loadSymbolData(symbol)
        }
    }
}