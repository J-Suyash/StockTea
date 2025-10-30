/*
 * StockTea - Enhanced Indian Portfolio Dashboard
 * Comprehensive view with Indian market features
 */
import QtQuick 2.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: dashboard
    
    property var portfolioData: main.currentPortfolio
    property bool compactMode: plasmoid.configuration.compactLayout
    
    color: Kirigami.Theme.backgroundColor
    
    Component {
        id: sectorChartComponent
        Canvas {
            width: 200
            height: 200
            onPaint: {
                var ctx = getContext("2d")
                var centerX = width / 2
                var centerY = height / 2
                var radius = Math.min(width, height) / 2 - 20
                
                ctx.clearRect(0, 0, width, height)
                
                if (!portfolioData || !portfolioData.sectorAllocation) return
                
                var sectors = Object.keys(portfolioData.sectorAllocation)
                var totalValue = portfolioData.totalValue
                var colors = PortfolioModelEnhanced.getSectorColors()
                
                var startAngle = -Math.PI / 2
                var currentAngle = startAngle
                
                sectors.forEach(function(sector) {
                    var allocation = portfolioData.sectorAllocation[sector]
                    var sliceAngle = (allocation.weight / 100) * 2 * Math.PI
                    
                    ctx.beginPath()
                    ctx.moveTo(centerX, centerY)
                    ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle)
                    ctx.closePath()
                    ctx.fillStyle = colors[sector] || colors['Others']
                    ctx.fill()
                    
                    currentAngle += sliceAngle
                })
            }
        }
    }
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: dashboard.width
        contentHeight: column.implicitHeight
        
        ColumnLayout {
            id: column
            width: scrollView.width
            
            spacing: 10
            
            // Portfolio Summary Header
            Rectangle {
                Layout.fillWidth: true
                height: compactMode ? 80 : 120
                color: Kirigami.Theme.highlightColor
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    PlasmaComponents.Label {
                        text: portfolioData.name || "My Indian Portfolio"
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                        font.bold: true
                        color: Kirigami.Theme.highlightedTextColor
                        Layout.fillWidth: true
                    }
                    
                    RowLayout {
                        PlasmaComponents.Label {
                            text: "₹" + (portfolioData.totalValue || 0).toLocaleString()
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.8
                            font.bold: true
                            color: Kirigami.Theme.positiveTextColor
                            Layout.fillWidth: true
                        }
                        
                        PlasmaComponents.Label {
                            text: PortfolioModelEnhanced.formatPercent(portfolioData.totalProfitLossPercent || 0)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                            font.bold: true
                            color: (portfolioData.totalProfitLoss || 0) >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                    }
                    
                    RowLayout {
                        PlasmaComponents.Label {
                            text: "P/L: ₹" + (portfolioData.totalProfitLoss || 0).toLocaleString()
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            color: (portfolioData.totalProfitLoss || 0) >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                        
                        PlasmaComponents.Label {
                            text: "Day: " + PortfolioModelEnhanced.formatINRNumber(portfolioData.dayChange || 0)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            color: (portfolioData.dayChange || 0) >= 0 ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                    }
                }
            }
            
            // Market Status and Quick Info
            GridLayout {
                Layout.fillWidth: true
                columns: compactMode ? 2 : 4
                
                // Market Status Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        PlasmaComponents.Label {
                            text: "Market Status"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        PlasmaComponents.Label {
                            text: indianMarketUtils.getMarketStatusText()
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                            font.bold: true
                            color: indianMarketUtils.isMarketOpen() ? 
                                   Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        }
                    }
                }
                
                // Positions Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        PlasmaComponents.Label {
                            text: "Positions"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        PlasmaComponents.Label {
                            text: (portfolioData.totalPositions || 0).toString()
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                            font.bold: true
                        }
                    }
                }
                
                // Win Rate Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        PlasmaComponents.Label {
                            text: "Win Rate"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        PlasmaComponents.Label {
                            text: portfolioData.totalPositions > 0 ? 
                                  Math.round((portfolioData.winningPositions / portfolioData.totalPositions) * 100) + "%" : "0%"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                            font.bold: true
                        }
                    }
                }
                
                // Diversification Score Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 6
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        
                        PlasmaComponents.Label {
                            text: "Diversification"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            color: Kirigami.Theme.disabledTextColor
                        }
                        
                        PlasmaComponents.Label {
                            text: (portfolioData.diversification || 0).toString() + "/100"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                            font.bold: true
                        }
                    }
                }
            }
            
            // Top Performers (if not compact)
            if (!compactMode && portfolioData.topGainer) {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    // Top Gainer
                    Rectangle {
                        Layout.fillWidth: true
                        height: 80
                        color: Kirigami.Theme.positiveTextColor + "20"
                        radius: 8
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            PlasmaComponents.Label {
                                text: "Top Gainer"
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: Kirigami.Theme.disabledTextColor
                            }
                            
                            PlasmaComponents.Label {
                                text: portfolioData.topGainer.symbol
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                font.bold: true
                            }
                            
                            PlasmaComponents.Label {
                                text: "+" + portfolioData.topGainer.profitLossPercent.toFixed(2) + "%"
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                                font.bold: true
                                color: Kirigami.Theme.positiveTextColor
                            }
                        }
                    }
                    
                    // Top Loser (if exists)
                    if (portfolioData.topLoser) {
                        Rectangle {
                            Layout.fillWidth: true
                            height: 80
                            color: Kirigami.Theme.negativeTextColor + "20"
                            radius: 8
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                
                                PlasmaComponents.Label {
                                    text: "Top Loser"
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    color: Kirigami.Theme.disabledTextColor
                                }
                                
                                PlasmaComponents.Label {
                                    text: portfolioData.topLoser.symbol
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                    font.bold: true
                                }
                                
                                PlasmaComponents.Label {
                                    text: portfolioData.topLoser.profitLossPercent.toFixed(2) + "%"
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                                    font.bold: true
                                    color: Kirigami.Theme.negativeTextColor
                                }
                            }
                        }
                    }
                }
            }
            
            // Sector Allocation (if not compact)
            if (!compactMode && portfolioData.sectorAllocation && Object.keys(portfolioData.sectorAllocation).length > 0) {
                Rectangle {
                    Layout.fillWidth: true
                    height: 300
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 8
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        
                        PlasmaComponents.Label {
                            text: "Sector Allocation"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // Pie Chart
                            Loader {
                                sourceComponent: sectorChartComponent
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 200
                            }
                            
                            // Sector List
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                PlasmaComponents.Label {
                                    text: "Sector"
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                
                                PlasmaComponents.Label {
                                    text: "Weight"
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    font.bold: true
                                }
                                
                                PlasmaComponents.Label {
                                    text: "Value (₹)"
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    font.bold: true
                                }
                                
                                Repeater {
                                    model: Object.keys(portfolioData.sectorAllocation)
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Rectangle {
                                            width: 12
                                            height: 12
                                            color: PortfolioModelEnhanced.getSectorColors()[modelData] || PortfolioModelEnhanced.getSectorColors()['Others']
                                            radius: 2
                                        }
                                        
                                        PlasmaComponents.Label {
                                            text: modelData
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                            Layout.fillWidth: true
                                        }
                                        
                                        PlasmaComponents.Label {
                                            text: PortfolioModelEnhanced.formatPercent(portfolioData.sectorAllocation[modelData].weight)
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                        }
                                        
                                        PlasmaComponents.Label {
                                            text: PortfolioModelEnhanced.formatINRShort(portfolioData.sectorAllocation[modelData].value)
                                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Recent Alerts (if enabled)
            if (plasmoid.configuration.portfolioAlerts && watchlistManager.alerts && watchlistManager.alerts.length > 0) {
                Rectangle {
                    Layout.fillWidth: true
                    height: 200
                    color: Kirigami.Theme.buttonBackgroundColor
                    radius: 8
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        
                        PlasmaComponents.Label {
                            text: "Recent Alerts"
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            model: watchlistManager.alerts.slice(0, 5) // Show last 5 alerts
                            
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 35
                                color: Kirigami.Theme.backgroundColor
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    
                                    PlasmaComponents.Label {
                                        text: modelData.symbol
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }
                                    
                                    PlasmaComponents.Label {
                                        text: modelData.condition + " ₹" + modelData.targetValue
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                    }
                                    
                                    PlasmaComponents.Label {
                                        text: modelData.triggered ? "TRIGGERED" : "ACTIVE"
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        font.bold: true
                                        color: modelData.triggered ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Refresh indicator
    PlasmaComponents.BusyIndicator {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 30
        height: 30
        running: main.loadingData.loadingDatainProgress
        visible: running
    }
    
    // Market hours indicator
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: 12
        height: 12
        radius: 6
        color: indianMarketUtils.isMarketOpen() ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
        
        Behavior on color {
            ColorAnimation { duration: 300 }
        }
    }
    
    // Import JavaScript modules
    Component.onCompleted: {
        // Make JavaScript modules available
        var PortfolioModelEnhanced = Qt.createQmlObject('import "./portfolio-model-enhanced.js" as PortfolioModelEnhanced', dashboard)
        var IndianMarketUtils = Qt.createQmlObject('import "./indian-market-utils.js" as IndianMarketUtils', dashboard)
        var WatchlistManager = Qt.createQmlObject('import "./watchlist-manager.js" as WatchlistManager', dashboard)
    }
}