/*
 * StockTea - Chart View
 * Candlestick chart visualization for stock data
 *
 */
import QtQuick 2.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import "../code/portfolio-model.js" as PortfolioModel
import "../code/stock-data-loader.js" as StockDataLoader

Item {
    id: chartView
    
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property string currentSymbol: ""
    property string currentTimeframe: "1d"
    property var candlestickData: []
    property int minCandleWidth: 4
    property int candleSpacing: 2
    
    signal symbolDataLoaded(string symbol, var data)
    
    function loadSymbolData(symbol) {
        currentSymbol = symbol
        loadCandlestickData(symbol, currentTimeframe)
    }
    
    function loadCandlestickData(symbol, timeframe) {
        if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
            main.dbgprint("Loading candlestick data for " + symbol + " with timeframe " + timeframe)
        }
        
        loadingIndicator.visible = true
        chartCanvas.visible = false
        
        var xhr = StockDataLoader.fetchCandlestickData(
            symbol,
            timeframe,
            function(jsonString) {
                var data = StockDataLoader.parseCandlestickData(jsonString, symbol)
                if (data && data.length > 0) {
                    candlestickData = data
                    updateChart()
                    symbolDataLoaded(symbol, data)
                } else {
                    showError(i18n("No chart data available"))
                }
                loadingIndicator.visible = false
                chartCanvas.visible = true
            },
                function(error) {
                    if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                        main.dbgprint("Failed to load candlestick data: " + error)
                    }
                    showError(i18n("Failed to load chart data: %1", error))
                loadingIndicator.visible = false
            }
        )
    }
    
    function updateChart() {
        if (candlestickData.length === 0) return
        updateLayoutMetrics()
        chartCanvas.requestPaint()
        updatePriceLabels()
        updateVolumeBars()
    }
    
    function updatePriceLabels() {
        if (candlestickData.length === 0) return

        var range = getVisibleRange()
        var minPrice = Number.MAX_VALUE
        var maxPrice = Number.MIN_VALUE

        for (var i = range.start; i <= range.end; i++) {
            var candle = candlestickData[i]
            minPrice = Math.min(minPrice, candle.low)
            maxPrice = Math.max(maxPrice, candle.high)
        }

        var priceRange = Math.max(0.0001, maxPrice - minPrice)
        var padding = priceRange * 0.1
        
        priceAxis.minPrice = minPrice - padding
        priceAxis.maxPrice = maxPrice + padding
    }
    
    function updateVolumeBars() {
        volumeBarsModel.clear()

        if (candlestickData.length === 0) return

        var maxVolume = 0
        for (var i = 0; i < candlestickData.length; i++) {
            maxVolume = Math.max(maxVolume, candlestickData[i].volume)
        }

        var step = getCandleStep()
        for (i = 0; i < candlestickData.length; i++) {
            var candle = candlestickData[i]
            var volumeHeight = maxVolume > 0 ? (candle.volume / maxVolume) * volumeArea.height : 0

            volumeBarsModel.append({
                x: i * step,
                width: Math.max(1, step - candleSpacing),
                height: volumeHeight,
                volume: candle.volume
            })
        }
    }

    function getCandleStep() {
        // Keep a minimum width per candle, allow zoom-out effect by viewport
        var base = minCandleWidth + candleSpacing
        return base
    }

    function updateLayoutMetrics() {
        var step = getCandleStep()
        var totalWidth = Math.max(chartFlick.width, candlestickData.length * step)
        plotContent.width = totalWidth
        chartCanvas.width = totalWidth
        volumeArea.width = totalWidth
    }

    function getVisibleRange() {
        var step = getCandleStep()
        var start = Math.floor(chartFlick.contentX / step)
        var end = Math.ceil((chartFlick.contentX + chartFlick.width) / step) - 1
        start = Math.max(0, Math.min(start, candlestickData.length - 1))
        end = Math.max(start, Math.min(end, candlestickData.length - 1))
        return { start: start, end: end }
    }
    
    function showError(message) {
        errorText.text = message
        errorText.visible = true
        chartCanvas.visible = false
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Chart controls
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaComponents.Label {
                text: currentSymbol ? i18n("Chart: %1", currentSymbol) : i18n("Select a position to view chart")
                font.pixelSize: defaultFontPixelSize * 1.1
                font.bold: true
                Layout.fillWidth: true
            }
            
            PlasmaComponents.ComboBox {
                id: timeframeCombo
                model: ["1m", "5m", "15m", "30m", "1h", "1d", "1w", "1M"]
                currentIndex: model.indexOf(currentTimeframe)
                onCurrentTextChanged: {
                    if (currentText !== currentTimeframe && currentSymbol) {
                        currentTimeframe = currentText
                        loadCandlestickData(currentSymbol, currentTimeframe)
                    }
                }
            }
            
            PlasmaComponents.Button {
                text: i18n("Reload")
                onClicked: {
                    if (currentSymbol) {
                        loadCandlestickData(currentSymbol, currentTimeframe)
                    }
                }
            }
        }
        
        // Chart area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            Item {
                id: chartArea
                anchors.fill: parent
                anchors.margins: 40

                // Price axis (fixed)
                Item {
                    id: priceAxis
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 40

                    property double minPrice: 0
                    property double maxPrice: 100

                    Repeater {
                        model: 5
                        delegate: PlasmaComponents.Label {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            y: (index / 4) * parent.height
                            text: PortfolioModel.formatCurrency(
                                priceAxis.maxPrice - (index / 4) * (priceAxis.maxPrice - priceAxis.minPrice),
                                ""
                            )
                            font.pixelSize: defaultFontPixelSize * 0.8
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // Scrollable plot area
                Flickable {
                    id: chartFlick
                    anchors.left: priceAxis.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    clip: true
                    contentWidth: plotContent.width
                    contentHeight: plotContent.height
                    interactive: true

                    onContentXChanged: updatePriceLabels()

                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOn }

                    Item {
                        id: plotContent
                        width: chartFlick.width
                        height: chartFlick.height

                        // Candle canvas
                        Canvas {
                            id: chartCanvas
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: parent.height - volumeArea.height - 5

                            onPaint: {
                                if (candlestickData.length === 0) return

                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var step = getCandleStep()
                                var candleWidth = Math.max(1, step - candleSpacing)
                                var priceRange = priceAxis.maxPrice - priceAxis.minPrice

                                for (var i = 0; i < candlestickData.length; i++) {
                                    var candle = candlestickData[i]
                                    var x = i * step + candleWidth / 2

                                    var openY = height - ((candle.open - priceAxis.minPrice) / priceRange) * height
                                    var closeY = height - ((candle.close - priceAxis.minPrice) / priceRange) * height
                                    var highY = height - ((candle.high - priceAxis.minPrice) / priceRange) * height
                                    var lowY = height - ((candle.low - priceAxis.minPrice) / priceRange) * height

                                    var isGreen = candle.close >= candle.open
                                    ctx.strokeStyle = isGreen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                    ctx.fillStyle = isGreen ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor

                                    ctx.beginPath()
                                    ctx.moveTo(x, highY)
                                    ctx.lineTo(x, lowY)
                                    ctx.stroke()

                                    if (Math.abs(closeY - openY) > 1) {
                                        ctx.fillRect(x - candleWidth / 2, Math.min(openY, closeY), candleWidth, Math.abs(closeY - openY))
                                    } else {
                                        ctx.beginPath()
                                        ctx.moveTo(x - candleWidth / 2, openY)
                                        ctx.lineTo(x + candleWidth / 2, openY)
                                        ctx.stroke()
                                    }
                                }
                            }
                        }

                        // Volume area scrolled with canvas
                        Rectangle {
                            id: volumeArea
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 60
                            color: "transparent"

                            ListModel { id: volumeBarsModel }

                            Repeater {
                                model: volumeBarsModel
                                delegate: Rectangle {
                                    x: model.x
                                    y: volumeArea.height - model.height
                                    width: model.width
                                    height: model.height
                                    color: Kirigami.Theme.disabledTextColor
                                    opacity: 0.6
                                }
                            }
                        }
                    }
                }
            
                // Loading indicator
                PlasmaComponents.BusyIndicator {
                    id: loadingIndicator
                    anchors.centerIn: chartArea
                    running: false
                    visible: false
                }
                
                // Error text
                PlasmaComponents.Label {
                    id: errorText
                    anchors.centerIn: chartArea
                    font.pixelSize: defaultFontPixelSize
                    color: Kirigami.Theme.negativeTextColor
                    visible: false
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                
                // Empty state
                PlasmaComponents.Label {
                    anchors.centerIn: chartArea
                    text: i18n("Click on a position to view its chart")
                    font.pixelSize: defaultFontPixelSize
                    color: Kirigami.Theme.disabledTextColor
                    visible: !currentSymbol && !loadingIndicator.visible && !errorText.visible
                }
            }
        }
    }

    onCandlestickDataChanged: {
        updateLayoutMetrics()
        updatePriceLabels()
        updateVolumeBars()
    }
    
    Component.onCompleted: {
        if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
            main.dbgprint("ChartView completed")
        }
    }
}
