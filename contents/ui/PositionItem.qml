/*
 * StockTea - Position Item
 * Individual stock position display component
 *
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
    
    Layout.fillWidth: true
    Layout.minimumWidth: 300
    Layout.preferredWidth: -1
    width: parent ? parent.width : implicitWidth
    height: Math.max(positionColumn.height + 10, defaultFontPixelSize * 8)
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
            // Load candlestick data for this position (prefer instrument_key for Upstox v3)
            var keyOrSymbol = position.instrument_key ? position.instrument_key : position.symbol
            loadCandlestickData(keyOrSymbol)
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

            PlasmaComponents.Button {
                text: i18n("Chart")
                icon.name: "application-x-chart"
                onClicked: loadCandlestickData(position.symbol)
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
        if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
            main.dbgprint("Loading candlestick data for: " + symbol)
        }
        
        // Find the FullRepresentation component to switch to chart tab
        var fullRep = null
        var parentItem = parent
        while (parentItem) {
            if (parentItem.objectName === "fullRepresentation") {
                fullRep = parentItem
                break
            }
            parentItem = parentItem.parent
        }
        
        if (fullRep && fullRep.mainTabBar) {
            fullRep.mainTabBar.currentIndex = 1
            
            // Load chart data after a brief delay to ensure view is switched
            Qt.callLater(function() {
                var stackView = fullRep.mainStackView
                if (stackView && stackView.currentItem && typeof stackView.currentItem.loadSymbolData === 'function') {
                    stackView.currentItem.loadSymbolData(symbol)
                }
            })
        }
    }
}
