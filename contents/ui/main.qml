/*
 * StockTea - Main QML Component
 * Adapted from weather widget architecture for financial data
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import Qt.labs.platform
import "../code/portfolio-model.js" as PortfolioModel
import "../code/upstox-data-loader.js" as StockDataLoader

PlasmoidItem {
    id: main

    /* Data Sources */
    Plasma5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 0
    }

    /* GUI layout stuff */
    compactRepresentation: compactRepresentation
    fullRepresentation: fullRepresentation

    // Full representation component
    Component {
        id: fullRepresentation
        FullRepresentation {
            anchors.fill: parent
        }
    }

    // Compact representation component
    Component {
        id: compactRepresentation
        Item {
            
            Layout.minimumWidth: 150
            Layout.minimumHeight: 40
            Layout.preferredWidth: 250
            Layout.preferredHeight: 50

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Kirigami.Icon {
                    source: "./piggy-bank-icon.svg"
                    Layout.preferredWidth: Math.min(parent.height - 8, 24)
                    Layout.preferredHeight: Math.min(parent.height - 8, 24)
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                }

                PlasmaComponents.Label {
                    text: main.currentPortfolio.name || "Portfolio"
                    font.pixelSize: Math.max(12, Math.min(parent.height - 16, 18))
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: main.expanded = !main.expanded
            }
        }
    }
    preferredRepresentation: onDesktop ? (desktopMode === 1 ? fullRepresentation : compactRepresentation) : compactRepresentation

    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    property bool onDesktop: (plasmoid.location === PlasmaCore.Types.Desktop || plasmoid.location === PlasmaCore.Types.Floating)

    toolTipTextFormat: Text.RichText

    // User Preferences
    property int desktopMode: plasmoid.configuration.desktopMode || 0
    property int refreshIntervalMin: plasmoid.configuration.refreshIntervalMin || 5
    property bool debugLogging: plasmoid.configuration.debugLogging || false
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "" || !plasmoid.configuration.widgetFontName) ? Kirigami.Theme.defaultFont : plasmoid.configuration.widgetFontName
    property int widgetFontSize: plasmoid.configuration.widgetFontSize || 20
    property bool inTray: ((plasmoid.parent ? (plasmoid.parent.containmentType === 129) : false) && ((plasmoid.formFactor === 2) || (plasmoid.formFactor === 3)))
    property string portfoliosStr: plasmoid.configuration.portfolios || "[]"
    property int widgetOrder: 0
    property int layoutType: 0

    // Cache, Last Load Time, Widget Status
    property string fullRepresentationAlias
    property string portfolioSummaryText: ""
    property bool portfolioModelChanged: false

    property var loadingData: ({
                                   loadingDatainProgress: false,
                                   loadingDataTimeoutMs: 15000,
                                   loadingXhrs: [],
                                   loadingError: false,
                                   lastloadingStartTime: 0,
                                   lastloadingSuccessTime: 0,
                                   failedAttemptCount: 0
                               })

    property string lastReloadedText: "⬇ " + i18n("%1 ago", "?? min")

    property var cacheData: ({
        plasmoidCacheId: plasmoid.id || "",
        cacheKey: "",
        cacheMap: ({}),
        alreadyLoadedFromCache: false
    })

    // Current Portfolio Data
    property var currentPortfolio: ({
                                        id: "",
                                        name: "",
                                        positions: [],
                                        totalValue: 0.0,
                                        totalCost: 0.0,
                                        totalProfitLoss: 0.0,
                                        totalProfitLossPercent: 0.0,
                                        dayChange: 0.0,
                                        dayChangePercent: 0.0,
                                        lastUpdate: new Date(),
                                        currency: "INR"
                                    })

    property int portfoliosCount: 0

    property var timerData: ({
                                 reloadIntervalMin: 0,
                                 reloadIntervalMs: 0,
                                 nextReload: 0
                             })

    property bool useOnlineStockData: true

    /* Data Models */
    property var portfolioModel
    property var positionsList: positionsModel
    ListModel {
        id: positionsModel
    }
    ListModel {
        id: candlestickModel
    }

    ListModel {
        id: networkLogs
    }

    function addNetworkLog(entry) {
        try {
            var e = entry || {}
            e.timestamp = e.timestamp || new Date().toISOString()
            networkLogs.append(e)
            if (networkLogs.count > 500) {
                networkLogs.remove(0, networkLogs.count - 500)
            }
        } catch (e2) {
        }
    }

    function clearNetworkLogs() {
        networkLogs.clear()
    }

    onLoadingDataCompleteChanged: {
        dbgprint2("loadingDataComplete:" + loadingDataComplete)
    }

    onPortfoliosStrChanged: {
        let portfolios = PortfolioModel.getPortfolioFromConfig()
        let count = portfolios.length
        if (count === 0) {
            return
        }
        let index = Math.max(0, Math.min(plasmoid.configuration.portfolioIndex || 0, count - 1))
        if (!portfolios[index] || !portfolios[index].name) {
            return
        }
        if (currentPortfolio.name !== portfolios[index].name) {
            setNextPortfolio(true)
        }
    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }
        print("[stockPortfolioWidget] " + msg)
    }

    function dbgprint2(msg) {
        if (!debugLogging) {
            return
        }
        console.log("\n\n")
        console.log("*".repeat(msg.length + 4))
        console.log("* " + msg +" *")
        console.log("*".repeat(msg.length + 4))
    }

    function dateNow() {
        var now = new Date().getTime()
        return now
    }

    function emptyPortfolioModel() {
        return PortfolioModel.createEmptyPortfolio()
    }

    function setNextPortfolio(initial, direction) {
        if (direction === undefined) {
            direction = "+"
        }
        
        currentPortfolio = emptyPortfolioModel()
        positionsModel.clear()
        candlestickModel.clear()

        var portfolios = PortfolioModel.getPortfolioFromConfig()
        portfoliosCount = portfolios.length
        var portfolioIndex = parseInt(plasmoid.configuration.portfolioIndex)
        if (isNaN(portfolioIndex)) {
            portfolioIndex = 0
        }
        dbgprint("portfolios count=" + portfoliosCount + ", portfolioIndex=" + plasmoid.configuration.portfolioIndex)
        
        if (!initial) {
            (direction === "+") ? portfolioIndex++ : portfolioIndex--
        }
        if (portfolioIndex > portfolios.length - 1) {
            portfolioIndex = 0
        }
        if (portfolioIndex < 0) {
            portfolioIndex = portfolios.length - 1
        }
        plasmoid.configuration.portfolioIndex = portfolioIndex
        dbgprint("portfolioIndex now: " + plasmoid.configuration.portfolioIndex)
        
        var portfolioObject = portfolios[portfolioIndex] || {
            id: "portfolio_" + portfolioIndex,
            name: i18n("Portfolio %1", portfolioIndex + 1),
            positions: [],
            currency: "INR"
        }
        currentPortfolio.id = portfolioObject.id || "portfolio_" + portfolioIndex
        currentPortfolio.name = portfolioObject.name || i18n("Portfolio %1", portfolioIndex + 1)
        currentPortfolio.positions = portfolioObject.positions || []
        currentPortfolio.currency = portfolioObject.currency || "INR"

        fullRepresentationAlias = currentPortfolio.name

        cacheData.cacheKey = PortfolioModel.generateCacheKey(currentPortfolio.id, "portfolio")
        cacheData.alreadyLoadedFromCache = false

        var ok = loadFromCache()
        dbgprint("CACHE " + ok)
        if (!ok) {
            loadDataFromInternet()
        }
    }

    function loadDataFromInternet() {
        dbgprint2("loadDataFromInternet")

        if (loadingData.loadingDatainProgress) {
            dbgprint("still loading")
            return
        }
        
        loadingDataComplete = false
        loadingData.loadingDatainProgress = true
        loadingData.lastloadingStartTime = dateNow()
        loadingData.nextReload = -1

        if (currentPortfolio.positions.length === 0) {
            dbgprint("No positions to load")
            loadingData.loadingDatainProgress = false
            loadingDataComplete = true
            return
        }

        var symbols = currentPortfolio.positions.map(pos => pos.symbol)
        var loadedCount = 0
        var totalSymbols = symbols.length
        var xhrs = []

        symbols.forEach(function(symbol, index) {
            // Check if we have instrument_key metadata for this symbol
            var position = currentPortfolio.positions.find(function(pos) {
                return pos.symbol === symbol
            })
            
            var symbolToFetch = symbol
            // Use instrument_key only if Upstox auth is configured; otherwise, keep plain symbol for Yahoo fallback
            var hasUpstoxAuth = !!plasmoid.configuration.upstoxAccessToken
            if (position && position.instrument_key && hasUpstoxAuth) {
                symbolToFetch = position.instrument_key
                dbgprint("Using instrument_key for " + symbol + ": " + symbolToFetch)
            } else if (position && position.instrument_key && !hasUpstoxAuth) {
                dbgprint("Upstox auth not configured; skipping instrument_key for " + symbol)
            }
            
            var xhr = StockDataLoader.fetchStockData(
                symbolToFetch,
                function(jsonString) {
                    var stockData = StockDataLoader.parseStockResponse(jsonString, symbol)
                    if (stockData) {
                        updatePositionData(symbol, stockData)
                    }
                    loadedCount++
                    
                    if (loadedCount === totalSymbols) {
                        dataLoadedFromInternet()
                    }
                },
                function(error) {
                    dbgprint("Failed to load data for " + symbol + " (" + symbolToFetch + "): " + error)
                    loadedCount++
                    
                    if (loadedCount === totalSymbols) {
                        dataLoadedFromInternet()
                    }
                }
            )
            xhrs.push(xhr)
        })

        loadingData.loadingXhrs = xhrs
    }

    function updatePositionData(symbol, stockData) {
        for (var i = 0; i < currentPortfolio.positions.length; i++) {
            var position = currentPortfolio.positions[i]
            if (position.symbol === symbol) {
                position.currentPrice = stockData.currentPrice
                position.dayChange = stockData.dayChange
                position.dayChangePercent = stockData.dayChangePercent
                position.lastUpdate = stockData.timestamp
                
                PortfolioModel.calculatePositionMetrics(position)
                break
            }
        }
    }

    function dataLoadedFromInternet() {
        dbgprint2("dataLoadedFromInternet")
        dbgprint("Data Loaded From Internet successfully")

        loadingData.lastloadingSuccessTime = dateNow()
        loadingData.loadingDatainProgress = false
        loadingData.nextReload = dateNow() + timerData.reloadIntervalMs
        loadingData.failedAttemptCount = 0
        currentPortfolio.nextReload = dateNow() + timerData.reloadIntervalMs

        PortfolioModel.calculatePortfolioMetrics(currentPortfolio)
        updatePositionsModel()
        updatePortfolioSummary()
        refreshTooltipSubText()
        dbgprint("portfolioModelChanged:" + portfolioModelChanged)
        portfolioModelChanged = !portfolioModelChanged

        saveToCache()
    }

    function reloadDataFailureCallback() {
        dbgprint("Failed to Load Data successfully")
        cacheData.loadingDatainProgress = false
        dbgprint("Error getting stock data. Scheduling data reload...")
        loadingData.nextReload = dateNow()
        loadFromCache()
    }

    function updateLastReloadedText() {
        dbgprint("updateLastReloadedText: " + loadingData.lastloadingSuccessTime)
        if (loadingData.lastloadingSuccessTime > 0) {
            lastReloadedText = '⬇ ' + PortfolioModel.getLastUpdateTimeText(loadingData.lastloadingSuccessTime)
        }
        var newStatus = getPlasmoidStatus(loadingData.lastloadingSuccessTime, 3600)
        dbgprint("Plasmoid status: " + newStatus)
    }

    function updatePortfolioSummary() {
        dbgprint2("updatePortfolioSummary")
        portfolioSummaryText = PortfolioModel.formatCurrency(currentPortfolio.totalValue, currentPortfolio.currency)
        if (currentPortfolio.totalProfitLoss !== 0) {
            portfolioSummaryText += " (" + PortfolioModel.formatPercent(currentPortfolio.totalProfitLossPercent) + ")"
        }
    }

    function updatePositionsModel() {
        dbgprint2("updatePositionsModel")
        positionsModel.clear()
        
        for (var i = 0; i < currentPortfolio.positions.length; i++) {
            var position = currentPortfolio.positions[i]
            
            // Ensure all required properties exist with default values
            var safePosition = {
                symbol: position.symbol || "",
                name: position.name || position.symbol || "",
                quantity: position.quantity || 0,
                buyingPrice: position.buyingPrice || 0,
                currentPrice: position.currentPrice || 0,
                totalValue: position.totalValue || 0,
                profitLoss: position.profitLoss || 0,
                profitLossPercent: position.profitLossPercent || 0,
                dayChange: position.dayChange || 0,
                dayChangePercent: position.dayChangePercent || 0,
                currency: position.currency || currentPortfolio.currency || "INR"
            }
            
            positionsModel.append(safePosition)
        }
    }

    function refreshTooltipSubText() {
        dbgprint2("refreshTooltipSubText")
        if (currentPortfolio.positions.length === 0) {
            dbgprint("portfolio not yet ready")
            return
        }

        var subText = ""
        subText += "<br /><br /><font size=\"4\">" + i18n("Total Value") + ": <b>" + PortfolioModel.formatCurrency(currentPortfolio.totalValue, currentPortfolio.currency) + "</b></font>"
        subText += "<br /><font size=\"4\">" + i18n("Total P/L") + ": <b>" + PortfolioModel.formatCurrency(currentPortfolio.totalProfitLoss, currentPortfolio.currency) + " (" + PortfolioModel.formatPercent(currentPortfolio.totalProfitLossPercent) + ")</b></font>"
        subText += "<br /><font size=\"4\">" + i18n("Day Change") + ": <b>" + PortfolioModel.formatCurrency(currentPortfolio.dayChange, currentPortfolio.currency) + " (" + PortfolioModel.formatPercent(currentPortfolio.dayChangePercent) + ")</b></font>"
        subText += "<br /><font size=\"3\">" + i18n("Positions") + ": " + currentPortfolio.positions.length + "</font>"

        toolTipMainText = currentPortfolio.name
        toolTipSubText = lastReloadedText + subText
    }

    function getPlasmoidStatus(lastReloaded, inTrayActiveTimeoutSec) {
        dbgprint2("getPlasmoidStatus")
        dbgprint("lastReloaded=" + lastReloaded)
        dbgprint("inTrayActiveTimeoutSec=" + inTrayActiveTimeoutSec)
        var reloadedAgoMs = getReloadedAgoMs(lastReloaded)
        dbgprint("reloadedAgoMs=" + reloadedAgoMs)
        if (reloadedAgoMs < inTrayActiveTimeoutSec * 1000) {
            return PlasmaCore.Types.ActiveStatus
        } else {
            return PlasmaCore.Types.PassiveStatus
        }
    }

    function getReloadedAgoMs(lastReloaded) {
        if (!lastReloaded) {
            lastReloaded = 0
        }
        return new Date().getTime() - lastReloaded
    }

    Component.onCompleted: {
        dbgprint2("MAIN.QML")
        dbgprint(JSON.stringify(currentPortfolio))

        if (plasmoid.configuration.firstRun) {
            if (plasmoid.configuration.widgetFontSize === undefined) {
                plasmoid.configuration.widgetFontSize = 20
                widgetFontSize = 20
            }

            // Set default portfolios if none exist
            var portfolios = PortfolioModel.getPortfolioFromConfig()
            if (portfolios.length === 0) {
                var defaultPortfolio = PortfolioModel.createEmptyPortfolio()
                defaultPortfolio.id = "default_portfolio"
                defaultPortfolio.name = i18n("My Portfolio")

                // Add some sample positions for demonstration (Indian stocks)
                var samplePositions = [
                    { symbol: "RELIANCE", name: "Reliance Industries", quantity: 10, buyingPrice: 2500.00 },
                    { symbol: "TCS", name: "Tata Consultancy Services", quantity: 5, buyingPrice: 3500.00 },
                    { symbol: "INFY", name: "Infosys Limited", quantity: 8, buyingPrice: 1500.00 }
                ]
                defaultPortfolio.positions = samplePositions

                portfolios.push(defaultPortfolio)
                PortfolioModel.savePortfolioToConfig(portfolios)
            }

            plasmoid.configuration.firstRun = false
        }

        timerData.reloadIntervalMin = plasmoid.configuration.refreshIntervalMin || 5
        timerData.reloadIntervalMs = timerData.reloadIntervalMin * 60000

        dbgprint("formFactor:" + plasmoid.formFactor)
        dbgprint("location:" + plasmoid.location)
        dbgprint("containment.containmentType:" + (plasmoid.parent ? plasmoid.parent.containmentType : "undefined"))
        if (inTray) {
            dbgprint("IN TRAY!")
        }

        dbgprint2(" Load Cache")
        var cacheContent = portfolioCache.readCache()

        dbgprint("readCache result length: " + cacheContent.length)

        if (cacheContent) {
            try {
                cacheData.cacheMap = JSON.parse(cacheContent)
                dbgprint("cacheMap initialized - keys:")
                for (var key in cacheData.cacheMap) {
                    dbgprint("  " + key + ", data: " + cacheData.cacheMap[key])
                }
            } catch (error) {
                dbgprint("error parsing cacheContent")
            }
        }
        cacheData.cacheMap = cacheData.cacheMap || {}

        dbgprint2("get Default Portfolio")
        setNextPortfolio(true)
    }

    function loadFromCache() {
        dbgprint2("loadFromCache")
        dbgprint('loading from cache, config key: ' + cacheData.cacheKey)

        if (cacheData.alreadyLoadedFromCache) {
            dbgprint('already loaded from cache')
            return true
        }
        
        // Try to load from memory cache first
        if (!cacheData.cacheMap || !cacheData.cacheMap[cacheData.cacheKey]) {
            dbgprint('memory cache not available, trying persistent cache')
            
            // Try to load from persistent storage
            var persistentCacheContent = portfolioCache.getCachedData()
            if (persistentCacheContent && persistentCacheContent.length > 0) {
                try {
                    cacheData.cacheMap = JSON.parse(persistentCacheContent)
                    dbgprint('Loaded cache from persistent storage')
                } catch (e) {
                    dbgprint('Error parsing persistent cache: ' + e.message)
                    return false
                }
            } else {
                dbgprint('no persistent cache available')
                return false
            }
        }

        if (cacheData.cacheMap[cacheData.cacheKey]) {
            currentPortfolio = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][1])
            updatePositionsModel()
            updatePortfolioSummary()
            refreshTooltipSubText()
            dbgprint("portfolioModelChanged:" + portfolioModelChanged)
            portfolioModelChanged = !portfolioModelChanged
            return true
        }

        dbgprint('cache key not found in cache map')
        return false
    }

    function saveToCache() {
        dbgprint2("saveCache")
        dbgprint(currentPortfolio.name)
        var cacheID = cacheData.cacheKey

        var contentToCache = {
            1: JSON.stringify(currentPortfolio),
            2: JSON.stringify(positionsModel),
            3: JSON.stringify(candlestickModel)
        }
        dbgprint("saving cacheKey = " + cacheID)
        cacheData.cacheMap[cacheID] = contentToCache
        
        // Save to persistent storage
        portfolioCache.writeCache(JSON.stringify(contentToCache))
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            dbgprint2("Timer Triggered")
            var now = dateNow()
            dbgprint("*** loadingData Flag : " + loadingData.loadingDatainProgress)
            dbgprint("*** loadingData failedAttemptCount : " + loadingData.failedAttemptCount)
            dbgprint("*** Last Load Success: " + (loadingData.lastloadingSuccessTime))
            dbgprint("*** Next Load Due    : " + (currentPortfolio.nextReload))
            dbgprint("*** Time Now         : " + now)
            dbgprint("*** Next Load in     : " + Math.round((currentPortfolio.nextReload - now) / 1000) + " sec = " + ((currentPortfolio.nextReload - now) / 60000).toFixed(2) + " min")

            updateLastReloadedText()

            if (loadingData.loadingDatainProgress) {
                dbgprint("Timeout in:" + (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs - now))
                if (now > (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs)) {
                    loadingData.failedAttemptCount++
                    let retryTime = Math.min(loadingData.failedAttemptCount, 30) * 30
                    console.log("Timed out downloading stock data - aborting attempt. Retrying in " + retryTime + " seconds time.")
                    loadingData.loadingDatainProgress = false
                    loadingData.lastloadingSuccessTime = 0
                    currentPortfolio.nextReload = now + (retryTime * 1000)
                    loadingDataComplete = true
                }
            } else {
                if (now > currentPortfolio.nextReload) {
                    loadDataFromInternet()
                }
            }
        }
    }

    property bool loadingDataComplete: false

    // Portfolio cache component
    Item {
        id: portfolioCache
        
        property string cacheDir: StandardPaths.writableLocation(StandardPaths.AppDataLocation) + "/plasma/plasma-org.kde.plasma.widgets.stocktea/"
        property string cacheFile: cacheDir + "portfolio_cache.json"
        
        function readCache() {
            var cacheData = ""
            try {
                // Use XMLHttpRequest for file I/O in QML
                var xhr = new XMLHttpRequest()
                var url = 'file://' + cacheFile
                dbgprint("Reading cache from: " + url)
                
                xhr.open('GET', url, false) // Synchronous request
                xhr.send()
                
                if (xhr.status === 200) {
                    cacheData = xhr.responseText
                    dbgprint("Cache read successfully, size: " + cacheData.length + " chars")
                } else {
                    dbgprint("Cache file not found or error reading: " + xhr.status)
                }
            } catch (e) {
                dbgprint("Cache read error: " + e.message)
            }
            return cacheData
        }
        
        function writeCache(data) {
            try {
                // For now, we'll store cache data in Qt settings as backup
                // since direct file I/O from QML is limited
                plasmoid.configuration.lastCacheData = data
                dbgprint("Cache data saved to configuration, length: " + data.length)
                
                // Also attempt to write to file if possible
                writeCacheToFile(data)
            } catch (e) {
                dbgprint("Cache write error: " + e.message)
            }
        }
        
        function writeCacheToFile(data) {
            try {
                // Create directory if it doesn't exist
                createCacheDirectory()
                
                // Note: Direct file writing from QML is limited
                // This is a placeholder for future implementation
                dbgprint("File cache write attempted for data length: " + data.length)
            } catch (e) {
                dbgprint("File cache write error: " + e.message)
            }
        }
        
        function createCacheDirectory() {
            try {
                // Directory creation would need to be done in Python or C++
                // For now, we'll rely on the configuration backup
                dbgprint("Cache directory: " + cacheDir)
            } catch (e) {
                dbgprint("Cache directory creation error: " + e.message)
            }
        }
        
        function getCachedData() {
            // Try to read from file first, then fallback to configuration
            var cachedContent = readCache()
            if (!cachedContent || cachedContent.length === 0) {
                cachedContent = plasmoid.configuration.lastCacheData || ""
            }
            return cachedContent
        }
    }
}
