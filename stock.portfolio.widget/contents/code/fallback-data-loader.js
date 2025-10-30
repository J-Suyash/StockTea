/*
 * Fallback Data Sources for Indian Equities
 * Provides multiple data sources with graceful fallback
 * Supports NSE/BSE, Yahoo Finance, and other free sources
 */

function FallbackDataSources() {
    this.sources = [
        this.createYahooFinanceSource(),
        this.createNSEBSEBhavSource(),
        this.createMarketStackSource(),
        this.createAlphaVantageSource()
    ]
}

FallbackDataSources.prototype.createYahooFinanceSource = function() {
    return {
        name: 'Yahoo Finance',
        priority: 1,
        enabled: true,
        fetchStockData: function(symbol, successCallback, failureCallback) {
            dbgprint('Fetching from Yahoo Finance: ' + symbol)
            
            // Convert Indian stock symbol for Yahoo Finance
            const yahooSymbol = convertToYahooFinanceFormat(symbol)
            const url = `https://query1.finance.yahoo.com/v8/finance/chart/${yahooSymbol}`
            
            return fetchJsonFromInternet(url, successCallback, failureCallback, this.parseYahooFinanceResponse.bind(this), symbol)
        },
        parseYahooFinanceResponse: function(jsonString, symbol) {
            try {
                const data = JSON.parse(jsonString)
                
                if (!data.chart || !data.chart.result || data.chart.result.length === 0) {
                    throw new Error('Invalid Yahoo Finance response')
                }
                
                const result = data.chart.result[0]
                const meta = result.meta || {}
                const timestamps = result.timestamp || []
                const quotes = result.indicators.quote[0] || {}
                
                if (timestamps.length === 0 || !quotes.close) {
                    throw new Error('No price data available')
                }
                
                const latestIndex = timestamps.length - 1
                const currentPrice = quotes.close[latestIndex] || 0
                const previousPrice = quotes.close[latestIndex - 1] || currentPrice
                const dayChange = currentPrice - previousPrice
                const dayChangePercent = previousPrice > 0 ? (dayChange / previousPrice) * 100 : 0
                
                return {
                    symbol: symbol,
                    currentPrice: currentPrice,
                    openPrice: quotes.open[latestIndex] || currentPrice,
                    highPrice: quotes.high[latestIndex] || currentPrice,
                    lowPrice: quotes.low[latestIndex] || currentPrice,
                    volume: quotes.volume[latestIndex] || 0,
                    timestamp: new Date(timestamps[latestIndex] * 1000),
                    dayChange: dayChange,
                    dayChangePercent: dayChangePercent,
                    currency: meta.currency || 'INR',
                    provider: 'yahoo',
                    marketCap: meta.marketCap || null
                }
            } catch (error) {
                dbgprint('Error parsing Yahoo Finance response: ' + error.message)
                return null
            }
        }
    }
}

FallbackDataSources.prototype.createNSEBSEBhavSource = function() {
    return {
        name: 'NSE/BSE Bhav',
        priority: 2,
        enabled: plasmoid.configuration.exchangeMode !== 2, // Not for both exchanges
        fetchStockData: function(symbol, successCallback, failureCallback) {
            dbgprint('Fetching from NSE/BSE: ' + symbol)
            
            // This is a simplified implementation
            // In practice, you'd fetch from official BSE/NSE data feeds
            const exchange = getExchangeForSymbol(symbol)
            const url = `https://www.bseindia.com/stockinfo/stockinfoeq_${exchange}_${symbol}.json`
            
            return fetchJsonFromInternet(url, successCallback, failureCallback, this.parseBhavResponse.bind(this), symbol)
        },
        parseBhavResponse: function(jsonString, symbol) {
            try {
                const data = JSON.parse(jsonString)
                const stockInfo = data.stockInfo || data.equityInfo || {}
                
                const currentPrice = parseFloat(stockInfo.LTP || stockInfo.lastPrice || 0)
                const openPrice = parseFloat(stockInfo.Open || stockInfo.openPrice || currentPrice)
                const highPrice = parseFloat(stockInfo.High || stockInfo.highPrice || currentPrice)
                const lowPrice = parseFloat(stockInfo.Low || stockInfo.lowPrice || currentPrice)
                const prevClose = parseFloat(stockInfo.prevClose || stockInfo.previousClose || currentPrice)
                const volume = parseInt(stockInfo.volumeQty || stockInfo.volume || 0)
                
                const dayChange = currentPrice - prevClose
                const dayChangePercent = prevClose > 0 ? (dayChange / prevClose) * 100 : 0
                
                return {
                    symbol: symbol,
                    currentPrice: currentPrice,
                    openPrice: openPrice,
                    highPrice: highPrice,
                    lowPrice: lowPrice,
                    previousClose: prevClose,
                    volume: volume,
                    timestamp: new Date(),
                    dayChange: dayChange,
                    dayChangePercent: dayChangePercent,
                    currency: 'INR',
                    provider: 'bse_nse',
                    exchange: stockInfo.exchange || 'NSE'
                }
            } catch (error) {
                dbgprint('Error parsing NSE/BSE response: ' + error.message)
                return null
            }
        }
    }
}

FallbackDataSources.prototype.createMarketStackSource = function() {
    const apiKey = plasmoid.configuration.marketstackApiKey || ''
    
    if (!apiKey) {
        return null // No API key available
    }
    
    return {
        name: 'MarketStack',
        priority: 3,
        enabled: true,
        fetchStockData: function(symbol, successCallback, failureCallback) {
            dbgprint('Fetching from MarketStack: ' + symbol)
            
            const url = `http://api.marketstack.com/v1/eod?access_key=${apiKey}&symbols=${symbol}&limit=1&sort=desc`
            
            return fetchJsonFromInternet(url, successCallback, failureCallback, this.parseMarketStackResponse.bind(this), symbol)
        },
        parseMarketStackResponse: function(jsonString, symbol) {
            try {
                const data = JSON.parse(jsonString)
                
                if (!data.data || data.data.length === 0) {
                    throw new Error('No data available from MarketStack')
                }
                
                const stockData = data.data[0]
                const currentPrice = stockData.close || 0
                const openPrice = stockData.open || currentPrice
                const highPrice = stockData.high || currentPrice
                const lowPrice = stockData.low || currentPrice
                const volume = stockData.volume || 0
                
                // Calculate day change (requires previous close)
                const prevClose = currentPrice // Simplified - would need previous day data
                const dayChange = 0
                const dayChangePercent = 0
                
                return {
                    symbol: symbol,
                    currentPrice: currentPrice,
                    openPrice: openPrice,
                    highPrice: highPrice,
                    lowPrice: lowPrice,
                    volume: volume,
                    timestamp: new Date(stockData.date || Date.now()),
                    dayChange: dayChange,
                    dayChangePercent: dayChangePercent,
                    currency: 'INR',
                    provider: 'marketstack',
                    exchange: stockData.exchange || 'NSE'
                }
            } catch (error) {
                dbgprint('Error parsing MarketStack response: ' + error.message)
                return null
            }
        }
    }
}

FallbackDataSources.prototype.createAlphaVantageSource = function() {
    const apiKey = plasmoid.configuration.alphaVantageKey || ''
    
    if (!apiKey) {
        return null // No API key available
    }
    
    return {
        name: 'Alpha Vantage',
        priority: 4,
        enabled: true,
        fetchStockData: function(symbol, successCallback, failureCallback) {
            dbgprint('Fetching from Alpha Vantage: ' + symbol)
            
            const url = `https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${apiKey}`
            
            return fetchJsonFromInternet(url, successCallback, failureCallback, this.parseAlphaVantageResponse.bind(this), symbol)
        },
        parseAlphaVantageResponse: function(jsonString, symbol) {
            try {
                const data = JSON.parse(jsonString)
                
                if (data['Error Message']) {
                    throw new Error('Alpha Vantage API Error: ' + data['Error Message'])
                }
                
                const quote = data['Global Quote']
                if (!quote) {
                    throw new Error('No quote data found')
                }
                
                const currentPrice = parseFloat(quote['05. price']) || 0
                const openPrice = parseFloat(quote['02. open']) || currentPrice
                const highPrice = parseFloat(quote['03. high']) || currentPrice
                const lowPrice = parseFloat(quote['04. low']) || currentPrice
                const volume = parseInt(quote['06. volume']) || 0
                const change = parseFloat(quote['09. change']) || 0
                const changePercent = parseFloat(quote['10. change percent'].replace('%', '')) || 0
                
                return {
                    symbol: symbol,
                    currentPrice: currentPrice,
                    openPrice: openPrice,
                    highPrice: highPrice,
                    lowPrice: lowPrice,
                    volume: volume,
                    timestamp: new Date(),
                    dayChange: change,
                    dayChangePercent: changePercent,
                    currency: 'INR',
                    provider: 'alphavantage',
                    peRatio: parseFloat(quote['10. change percent']) || null
                }
            } catch (error) {
                dbgprint('Error parsing Alpha Vantage response: ' + error.message)
                return null
            }
        }
    }
}

FallbackDataSources.prototype.fetchWithFallback = function(symbol, successCallback, failureCallback) {
    const tryNextSource = (sourceIndex) => {
        if (sourceIndex >= this.sources.length) {
            failureCallback('All data sources failed')
            return
        }
        
        const source = this.sources[sourceIndex]
        if (!source || !source.enabled) {
            tryNextSource(sourceIndex + 1)
            return
        }
        
        dbgprint(`Trying data source: ${source.name}`)
        
        source.fetchStockData(symbol, 
            (data) => {
                if (data) {
                    successCallback(data)
                } else {
                    tryNextSource(sourceIndex + 1)
                }
            },
            (error) => {
                dbgprint(`Source ${source.name} failed: ${error}`)
                tryNextSource(sourceIndex + 1)
            }
        )
    }
    
    tryNextSource(0)
}

// Utility functions for fallback sources
function fetchJsonFromInternet(url, successCallback, failureCallback, parseFunction, symbol) {
    const xhr = new XMLHttpRequest()
    xhr.timeout = plasmoid.configuration.apiTimeout || 15000
    
    dbgprint('GET url opening: ' + url)
    xhr.open('GET', url)
    xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) StockPortfolioWidget/2.0")
    
    xhr.ontimeout = () => {
        dbgprint('Request timeout: ' + xhr.status)
        failureCallback('Request timeout')
    }
    
    xhr.onerror = (event) => {
        dbgprint('Network error: ' + xhr.status)
        failureCallback('Network error')
    }
    
    xhr.onload = () => {
        if (xhr.status !== 200) {
            failureCallback('HTTP error: ' + xhr.status)
            return
        }
        
        try {
            const jsonString = xhr.responseText
            if (!isValidJson(jsonString)) {
                failureCallback('Invalid JSON response')
                return
            }
            
            successCallback(jsonString)
        } catch (error) {
            failureCallback('JSON parsing error: ' + error.message)
        }
    }
    
    xhr.send()
    return xhr
}

function isValidJson(str) {
    try {
        JSON.parse(str)
    } catch (e) {
        return false
    }
    return true
}

function convertToYahooFinanceFormat(symbol) {
    // Handle Indian stock symbols for Yahoo Finance
    if (symbol.includes('NSE_EQ|') || symbol.includes('BSE_EQ|')) {
        // Extract symbol from Upstox format
        const cleanSymbol = symbol.split('|')[1] || symbol.split('-')[0]
        return `${cleanSymbol}.NS` // NSE
    }
    
    if (symbol.endsWith('.NS') || symbol.endsWith('.BO')) {
        return symbol
    }
    
    if (symbol.includes('-EQ')) {
        const cleanSymbol = symbol.replace('-EQ', '')
        return `${cleanSymbol}.NS`
    }
    
    // Default to NSE
    return `${symbol}.NS`
}

function getExchangeForSymbol(symbol) {
    // Simple heuristic - in practice, you'd have a symbol database
    if (symbol.includes('BSE') || symbol.length <= 6) {
        return 'eq'
    }
    return 'eq' // Default to NSE
}