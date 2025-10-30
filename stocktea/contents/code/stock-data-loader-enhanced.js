/*
 * Enhanced Stock Data Loader for Indian Equities
 * Unified interface with Upstox API, fallbacks, and Indian market features
 */

.import "./upstox-data-loader.js" as UpstoxAPI
.import "./fallback-data-loader.js" as FallbackData
.import "./indian-market-utils.js" as IndianMarket
.import "./watchlist-manager.js" as WatchlistManager

function StockDataLoader() {
    this.upstoxAPI = new UpstoxAPI.UpstoxAPI()
    this.fallbackSources = new FallbackData.FallbackDataSources()
    this.indianMarket = new IndianMarket.IndianMarketUtils()
    this.watchlistManager = new WatchlistManager.WatchlistManager()
    this.cache = {}
    this.lastUpdateTimes = {}
}

StockDataLoader.prototype.fetchStockData = function(symbol, successCallback, failureCallback) {
    dbgprint('Fetching stock data for symbol: ' + symbol)
    
    // Check offline mode first
    if (plasmoid.configuration.offlineMode) {
        const cachedData = this.getCachedData(symbol)
        if (cachedData) {
            successCallback(cachedData)
            return
        }
    }
    
    // Validate Indian symbol
    const validation = this.indianMarket.validateIndianSymbol(symbol)
    if (!validation.isValid) {
        failureCallback('Invalid symbol: ' + validation.errors.join(', '))
        return
    }
    
    const normalizedSymbol = validation.normalizedSymbol
    
    // Try primary data source (Upstox)
    if (this.shouldUseUpstox()) {
        this.fetchFromUpstox(normalizedSymbol, successCallback, failureCallback)
    } else {
        // Use fallback sources
        this.fetchFromFallback(normalizedSymbol, successCallback, failureCallback)
    }
}

StockDataLoader.prototype.fetchFromUpstox = function(symbol, successCallback, failureCallback) {
    if (!this.upstoxAPI.apiKey || !this.upstoxAPI.accessToken) {
        dbgprint('Upstox credentials not available, falling back')
        this.fetchFromFallback(symbol, successCallback, failureCallback)
        return
    }
    
    this.upstoxAPI.fetchMarketQuote(symbol, 
        (data) => {
            const stockData = this.upstoxAPI.parseMarketQuote(data, symbol)
            if (stockData) {
                this.cacheData(symbol, stockData)
                this.watchlistManager.updatePriceHistory(symbol, stockData.currentPrice)
                this.watchlistManager.checkAlerts(symbol, stockData.currentPrice, stockData.previousClose, stockData.dayChangePercent)
                successCallback(stockData)
            } else {
                this.fetchFromFallback(symbol, successCallback, failureCallback)
            }
        },
        (error) => {
            dbgprint('Upstox API failed: ' + error)
            if (plasmoid.configuration.enableFallback) {
                this.fetchFromFallback(symbol, successCallback, failureCallback)
            } else {
                failureCallback('Upstox API failed: ' + error)
            }
        }
    )
}

StockDataLoader.prototype.fetchFromFallback = function(symbol, successCallback, failureCallback) {
    this.fallbackSources.fetchWithFallback(symbol,
        (data) => {
            if (data) {
                this.cacheData(symbol, data)
                this.watchlistManager.updatePriceHistory(symbol, data.currentPrice)
                this.watchlistManager.checkAlerts(symbol, data.currentPrice, data.previousClose || data.currentPrice, data.dayChangePercent)
                successCallback(data)
            } else {
                failureCallback('All data sources failed')
            }
        },
        (error) => {
            failureCallback(error)
        }
    )
}

StockDataLoader.prototype.fetchCandlestickData = function(symbol, timeframe, successCallback, failureCallback) {
    dbgprint('Fetching candlestick data for symbol: ' + symbol + ', timeframe: ' + timeframe)
    
    // Check cache first
    const cacheKey = this.getCandlestickCacheKey(symbol, timeframe)
    const cachedData = this.cache[cacheKey]
    
    if (cachedData && this.isCacheValid(cachedData.timestamp)) {
        successCallback(cachedData.data)
        return
    }
    
    if (this.shouldUseUpstox()) {
        this.fetchCandlesFromUpstox(symbol, timeframe, successCallback, failureCallback)
    } else {
        this.fetchCandlesFromFallback(symbol, timeframe, successCallback, failureCallback)
    }
}

StockDataLoader.prototype.fetchCandlesFromUpstox = function(symbol, timeframe, successCallback, failureCallback) {
    if (!this.upstoxAPI.apiKey || !this.upstoxAPI.accessToken) {
        this.fetchCandlesFromFallback(symbol, timeframe, successCallback, failureCallback)
        return
    }
    
    // Calculate date range
    const toDate = new Date().toISOString().split('T')[0]
    const fromDate = this.getFromDateForTimeframe(timeframe)
    
    this.upstoxAPI.fetchHistoricalCandles(symbol, timeframe, fromDate, toDate,
        (data) => {
            const candles = this.upstoxAPI.parseHistoricalCandles(data, symbol)
            if (candles && candles.length > 0) {
                this.cacheCandlestickData(symbol, timeframe, candles)
                successCallback(candles)
            } else {
                this.fetchCandlesFromFallback(symbol, timeframe, successCallback, failureCallback)
            }
        },
        (error) => {
            dbgprint('Upstox candles failed: ' + error)
            this.fetchCandlesFromFallback(symbol, timeframe, successCallback, failureCallback)
        }
    )
}

StockDataLoader.prototype.fetchCandlesFromFallback = function(symbol, timeframe, successCallback, failureCallback) {
    // Use Yahoo Finance for chart data as fallback
    const yahooSymbol = this.convertToYahooFormat(symbol)
    const interval = this.getYahooInterval(timeframe)
    const range = this.getYahooRange(timeframe)
    
    const url = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}?interval=${interval}&range=${range}`
    
    fetchJsonFromInternet(url, 
        (jsonString) => {
            try {
                const data = JSON.parse(jsonString)
                const candles = this.parseYahooCandles(data, symbol)
                if (candles && candles.length > 0) {
                    this.cacheCandlestickData(symbol, timeframe, candles)
                    successCallback(candles)
                } else {
                    failureCallback('No candlestick data available')
                }
            } catch (error) {
                failureCallback('Error parsing chart data: ' + error.message)
            }
        },
        (error) => {
            failureCallback('Chart data fetch failed: ' + error)
        }
    )
}

StockDataLoader.prototype.parseYahooCandles = function(yahooData, symbol) {
    try {
        if (!yahooData.chart || !yahooData.chart.result || yahooData.chart.result.length === 0) {
            return []
        }
        
        const result = yahooData.chart.result[0]
        const timestamps = result.timestamp || []
        const quotes = result.indicators.quote[0] || {}
        
        const candles = []
        
        for (let i = 0; i < timestamps.length; i++) {
            if (quotes.close[i] !== null && quotes.close[i] !== undefined) {
                candles.push({
                    timestamp: new Date(timestamps[i] * 1000),
                    open: quotes.open[i] || quotes.close[i],
                    high: quotes.high[i] || quotes.close[i],
                    low: quotes.low[i] || quotes.close[i],
                    close: quotes.close[i],
                    volume: quotes.volume[i] || 0
                })
            }
        }
        
        return candles.sort((a, b) => a.timestamp - b.timestamp)
    } catch (error) {
        dbgprint('Error parsing Yahoo Finance candles: ' + error.message)
        return []
    }
}

StockDataLoader.prototype.shouldUseUpstox = function() {
    const provider = plasmoid.configuration.apiProvider || 0
    return provider === 0 && this.upstoxAPI.apiKey && this.upstoxAPI.accessToken
}

StockDataLoader.prototype.getCachedData = function(symbol) {
    const cacheKey = this.getStockCacheKey(symbol)
    const cached = this.cache[cacheKey]
    
    if (cached && this.isCacheValid(cached.timestamp)) {
        return cached.data
    }
    
    return null
}

StockDataLoader.prototype.cacheData = function(symbol, data) {
    const cacheKey = this.getStockCacheKey(symbol)
    this.cache[cacheKey] = {
        data: data,
        timestamp: Date.now()
    }
}

StockDataLoader.prototype.cacheCandlestickData = function(symbol, timeframe, data) {
    const cacheKey = this.getCandlestickCacheKey(symbol, timeframe)
    this.cache[cacheKey] = {
        data: data,
        timestamp: Date.now()
    }
}

StockDataLoader.prototype.getStockCacheKey = function(symbol) {
    return `stock_${symbol.toUpperCase()}`
}

StockDataLoader.prototype.getCandlestickCacheKey = function(symbol, timeframe) {
    return `candles_${symbol.toUpperCase()}_${timeframe}`
}

StockDataLoader.prototype.isCacheValid = function(timestamp) {
    const cacheTimeout = (plasmoid.configuration.refreshIntervalSec || 30) * 1000
    return Date.now() - timestamp < cacheTimeout
}

StockDataLoader.prototype.getFromDateForTimeframe = function(timeframe) {
    const now = new Date()
    const daysBack = {
        '1m': 1,
        '5m': 1,
        '15m': 2,
        '30m': 3,
        '1h': 7,
        '1d': 30,
        '1w': 90,
        '1M': 365
    }
    
    const days = daysBack[timeframe] || 30
    const fromDate = new Date(now.getTime() - (days * 24 * 60 * 60 * 1000))
    
    return fromDate.toISOString().split('T')[0]
}

StockDataLoader.prototype.getYahooInterval = function(timeframe) {
    return timeframe // Yahoo Finance uses same interval names
}

StockDataLoader.prototype.getYahooRange = function(timeframe) {
    const ranges = {
        '1m': '1d',
        '5m': '1d',
        '15m': '1d',
        '30m': '1d',
        '1h': '5d',
        '1d': '1mo',
        '1w': '6mo',
        '1M': '2y'
    }
    return ranges[timeframe] || '1mo'
}

StockDataLoader.prototype.convertToYahooFormat = function(symbol) {
    // Convert Indian symbol to Yahoo Finance format
    if (symbol.includes('NSE_EQ|') || symbol.includes('BSE_EQ|')) {
        const cleanSymbol = symbol.split('|')[1] || symbol.split('-')[0]
        return `${cleanSymbol}.NS` // NSE
    }
    
    if (symbol.includes('-EQ')) {
        const cleanSymbol = symbol.replace('-EQ', '')
        return `${cleanSymbol}.NS`
    }
    
    if (!symbol.includes('.')) {
        return `${symbol}.NS`
    }
    
    return symbol
}

// Legacy compatibility functions
function fetchStockData(symbol, successCallback, failureCallback) {
    const loader = new StockDataLoader()
    loader.fetchStockData(symbol, successCallback, failureCallback)
}

function fetchCandlestickData(symbol, timeframe, successCallback, failureCallback) {
    const loader = new StockDataLoader()
    loader.fetchCandlestickData(symbol, timeframe, successCallback, failureCallback)
}

// Enhanced API with Indian market features
StockDataLoader.prototype.getMarketStatus = function() {
    return this.indianMarket.getMarketStatusText()
}

StockDataLoader.prototype.isMarketOpen = function() {
    return this.indianMarket.isMarketOpen()
}

StockDataLoader.prototype.getWatchlists = function() {
    return this.watchlistManager.watchlists
}

StockDataLoader.prototype.getAlerts = function() {
    return this.watchlistManager.alerts
}

StockDataLoader.prototype.addPriceAlert = function(alert) {
    return this.watchlistManager.addPriceAlert(alert)
}

StockDataLoader.prototype.getPortfolioData = function(successCallback, failureCallback) {
    if (this.shouldUseUpstox() && this.upstoxAPI.accessToken) {
        this.upstoxAPI.fetchPortfolioPositions(successCallback, failureCallback)
    } else {
        failureCallback('Portfolio data only available through Upstox API')
    }
}

StockDataLoader.prototype.fetchMultipleStocks = function(symbols, successCallback, failureCallback) {
    const results = []
    let completed = 0
    
    symbols.forEach(symbol => {
        this.fetchStockData(symbol,
            (data) => {
                results.push(data)
                completed++
                
                if (completed === symbols.length) {
                    successCallback(results)
                }
            },
            (error) => {
                dbgprint(`Failed to fetch data for ${symbol}: ${error}`)
                completed++
                
                if (completed === symbols.length) {
                    successCallback(results)
                }
            }
        )
    })
}

// Export for use in other files
var stockDataLoader = new StockDataLoader()