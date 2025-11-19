/*
 * Stock data loading and API communication utilities
 * Adapted from weather widget data-loader.js for financial data
 */

function fetchStockData(symbol, successCallback, failureCallback) {
    dbgprint('Fetching stock data for symbol: ' + symbol)
    
    var apiUrl = buildApiUrl(symbol)
    return fetchJsonFromInternet(apiUrl, successCallback, failureCallback)
}

function fetchCandlestickData(symbol, timeframe, successCallback, failureCallback) {
    dbgprint('Fetching candlestick data for symbol: ' + symbol + ', timeframe: ' + timeframe)
    
    var apiUrl = buildCandlestickUrl(symbol, timeframe)
    return fetchJsonFromInternet(apiUrl, successCallback, failureCallback)
}

// Optional: fetch with explicit Yahoo range override (e.g., '3mo','6mo','1y')
function fetchCandlestickDataWithRange(symbol, timeframe, rangeOverride, successCallback, failureCallback) {
    dbgprint('Fetching candlestick data with range for symbol: ' + symbol + ', timeframe: ' + timeframe + ', range: ' + rangeOverride)
    var ySymbol = normalizeYahooSymbol(symbol)
    var interval = mapToYahooInterval(timeframe)
    var desired = String(rangeOverride || mapToYahooRange(timeframe))
    var range = mapToYahooSafeRange(interval, desired)
    var apiUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/' + ySymbol + '?interval=' + interval + '&range=' + range
    return fetchJsonFromInternet(apiUrl, successCallback, failureCallback)
}

function mapToYahooSafeRange(interval, desiredRange) {
    // Yahoo imposes constraints: 1m → up to 7d; 5m/15m → up to 1mo; 30m/60m → up to a few months; 1d → years.
    // Keep conservative, avoid 422/400 errors.
    const safe = {
        '1m': ['1d', '5d'],
        '5m': ['5d', '1mo'],
        '15m': ['1mo'],
        '30m': ['1mo'],
        '60m': ['1mo'],
        '1d': ['1mo', '3mo', '6mo', '1y', '2y', '5y', '10y'],
        '1wk': ['1y', '2y', '5y', '10y'],
        '1mo': ['1y', '2y', '5y', '10y']
    }
    const list = safe[interval] || ['1mo']
    if (list.indexOf(desiredRange) !== -1) return desiredRange
    // pick the largest safe range for this interval
    return list[list.length - 1]
}

function buildApiUrl(symbol) {
    var ySymbol = normalizeYahooSymbol(symbol)
    return 'https://query1.finance.yahoo.com/v8/finance/chart/' + ySymbol
}

function buildCandlestickUrl(symbol, timeframe) {
    var ySymbol = normalizeYahooSymbol(symbol)
    var interval = mapToYahooInterval(timeframe)
    var range = mapToYahooRange(timeframe)
    return 'https://query1.finance.yahoo.com/v8/finance/chart/' + ySymbol + '?interval=' + interval + '&range=' + range
}

function normalizeYahooSymbol(symbol) {
    if (!symbol) return ''
    var s = String(symbol).trim().toUpperCase()
    if (s.endsWith('.NS') || s.endsWith('.BO')) return s
    if (s.endsWith('-EQ')) s = s.slice(0, -3)
    if (/^[A-Z0-9]{2,10}$/.test(s)) return s + '.NS'
    return s
}

function mapToYahooInterval(timeframe) {
    var tf = String(timeframe || '1d')
    var mapping = {
        '1m': '1m',
        '5m': '5m',
        '15m': '15m',
        '30m': '30m',
        '1h': '60m',
        '1d': '1d',
        '1w': '1wk',
        '1M': '1mo'
    }
    return mapping[tf] || '1d'
}

function mapToYahooRange(timeframe) {
    var tf = String(timeframe || '1d')
    var mapping = {
        '1m': '1d',
        '5m': '1d',
        '15m': '5d',
        '30m': '5d',
        '1h': '1mo',
        '1d': '1mo',
        '1w': '6mo',
        '1M': '1y'
    }
    return mapping[tf] || '1mo'
}

function getTimespanFromTimeframe(timeframe) {
    var mapping = {
        '1m': 'minute',
        '5m': 'minute',
        '15m': 'minute',
        '30m': 'minute',
        '1h': 'hour',
        '1d': 'day',
        '1w': 'week',
        '1M': 'month'
    }
    return mapping[timeframe] || 'day'
}

function getMultiplierFromTimeframe(timeframe) {
    var mapping = {
        '1m': 1,
        '5m': 5,
        '15m': 15,
        '30m': 30,
        '1h': 1,
        '1d': 1,
        '1w': 1,
        '1M': 1
    }
    return mapping[timeframe] || 1
}

function getAlphaVantageInterval(timeframe) {
    var mapping = {
        '1m': '1min',
        '5m': '5min',
        '15m': '15min',
        '30m': '30min',
        '1h': '60min'
    }
    return mapping[timeframe] || '5min'
}

function fetchJsonFromInternet(getUrl, successCallback, failureCallback) {
    dbgprint2("fetchJsonFromInternet")
    var xhr = new XMLHttpRequest()
    xhr.timeout = loadingData.loadingDataTimeoutMs || 15000
    dbgprint('GET url opening: ' + getUrl)
    var startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: getUrl })
    xhr.open('GET', getUrl)
    xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 StockPortfolioWidget/1.0")
    dbgprint('GET url sending: ' + getUrl)
    xhr.send()

    xhr.ontimeout = function() {
        dbgprint('ERROR - timeout: ' + xhr.status)
        emitNetworkLog({ phase: 'timeout', method: 'GET', url: getUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Request timeout')
    }

    xhr.onerror = function(event) {
        dbgprint('ERROR - status: ' + xhr.status)
        dbgprint('ERROR - responseText: ' + xhr.responseText)
        emitNetworkLog({ phase: 'error', method: 'GET', url: getUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Network error')
    }

    xhr.onload = function() {
        dbgprint('status: ' + xhr.status)
        var ok = xhr.status === 200
        emitNetworkLog({ phase: 'load', method: 'GET', url: getUrl, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.responseText ? xhr.responseText.length : 0) })
        
        if (xhr.status !== 200) {
            dbgprint('ERROR - HTTP status: ' + xhr.status)
            failureCallback('HTTP error: ' + xhr.status)
            return
        }

        var jsonString = xhr.responseText
        if (!isJsonString(jsonString)) {
            dbgprint('incoming jsonString is not valid: ' + jsonString)
            failureCallback('Invalid JSON response')
            return
        }
        dbgprint('incoming text seems to be valid')

        successCallback(jsonString)
    }
    
    dbgprint('GET called for url: ' + getUrl)
    return xhr
}

function emitNetworkLog(entry) {
    try {
        if (typeof main !== 'undefined' && typeof main.addNetworkLog === 'function') {
            var e = entry || {}
            e.timestamp = new Date().toISOString()
            main.addNetworkLog(e)
        }
    } catch (e) {
    }
}

function isJsonString(str) {
    try {
        JSON.parse(str)
    } catch (e) {
        return false
    }
    return true
}

function parsePolygonQuoteResponse(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)
        
        if (data.status !== 'OK' || !data.results || data.results.length === 0) {
            throw new Error('Invalid response from Polygon API')
        }
        
        var result = data.results[0]
        return {
            symbol: symbol,
            currentPrice: result.c || 0, // Close price
            openPrice: result.o || 0,
            highPrice: result.h || 0,
            lowPrice: result.l || 0,
            volume: result.v || 0,
            timestamp: new Date(result.t || Date.now()),
            dayChange: 0, // Will be calculated
            dayChangePercent: 0 // Will be calculated
        }
    } catch (error) {
        dbgprint('Error parsing Polygon response: ' + error.message)
        return null
    }
}

function parseAlphaVantageQuoteResponse(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)
        
        if (data['Error Message']) {
            throw new Error('API Error: ' + data['Error Message'])
        }
        
        var quote = data['Global Quote'] || data['Time Series (1min)']
        if (!quote) {
            throw new Error('No quote data found')
        }
        
        // Handle different response formats
        var priceData
        if (data['Global Quote']) {
            priceData = {
                currentPrice: parseFloat(quote['05. price']) || 0,
                openPrice: parseFloat(quote['02. open']) || 0,
                highPrice: parseFloat(quote['03. high']) || 0,
                lowPrice: parseFloat(quote['04. low']) || 0,
                volume: parseInt(quote['06. volume']) || 0,
                change: parseFloat(quote['09. change']) || 0,
                changePercent: parseFloat(quote['10. change percent'].replace('%', '')) || 0
            }
        } else {
            // For intraday data, get the latest entry
            var timestamps = Object.keys(quote)
            var latestTimestamp = timestamps[0]
            var latestData = quote[latestTimestamp]
            
            priceData = {
                currentPrice: parseFloat(latestData['4. close']) || 0,
                openPrice: parseFloat(latestData['1. open']) || 0,
                highPrice: parseFloat(latestData['2. high']) || 0,
                lowPrice: parseFloat(latestData['3. low']) || 0,
                volume: parseInt(latestData['5. volume']) || 0,
                change: 0,
                changePercent: 0
            }
        }
        
        return {
            symbol: symbol,
            currentPrice: priceData.currentPrice || 0,
            openPrice: priceData.openPrice || 0,
            highPrice: priceData.highPrice || 0,
            lowPrice: priceData.lowPrice || 0,
            volume: priceData.volume || 0,
            timestamp: new Date(),
            dayChange: priceData.change || 0,
            dayChangePercent: priceData.changePercent || 0
        }
    } catch (error) {
        dbgprint('Error parsing Alpha Vantage response: ' + error.message)
        return null
    }
}

function parseYahooFinanceResponse(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)
        
        if (!data.chart || !data.chart.result || data.chart.result.length === 0) {
            throw new Error('Invalid response from Yahoo Finance')
        }
        
        var result = data.chart.result[0]
        var meta = result.meta || {}
        var timestamps = result.timestamp || []
        var quotes = result.indicators.quote[0] || {}
        
        if (timestamps.length === 0 || !quotes.close) {
            throw new Error('No price data available')
        }
        
        var latestIndex = timestamps.length - 1
        var currentPrice = quotes.close[latestIndex] || 0
        var previousPrice = quotes.close[latestIndex - 1] || currentPrice
        var dayChange = currentPrice - previousPrice
        var dayChangePercent = previousPrice > 0 ? (dayChange / previousPrice) * 100 : 0
        
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
            currency: meta.currency || 'USD'
        }
    } catch (error) {
        dbgprint('Error parsing Yahoo Finance response: ' + error.message)
        return null
    }
}

function parseCandlestickData(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)
        var candlesticks = []
        
        // Handle different API response formats
        if (data.results && typeof data.results.length === 'number') {
            // Polygon.io format
            for (var i = 0; i < data.results.length; i++) {
                var item = data.results[i]
                candlesticks.push({
                    timestamp: new Date(item.t),
                    open: item.o,
                    high: item.h,
                    low: item.l,
                    close: item.c,
                    volume: item.v
                })
            }
        } else if (data.chart && data.chart.result) {
            // Yahoo Finance format
            var result = data.chart.result[0]
            var timestamps = result.timestamp || []
            var quotes = result.indicators.quote[0] || {}
            
            for (var j = 0; j < timestamps.length; j++) {
                if (quotes.close[j] !== null && quotes.close[j] !== undefined) {
                    candlesticks.push({
                        timestamp: new Date(timestamps[j] * 1000),
                        open: quotes.open[j] || quotes.close[j],
                        high: quotes.high[j] || quotes.close[j],
                        low: quotes.low[j] || quotes.close[j],
                        close: quotes.close[j],
                        volume: quotes.volume[j] || 0
                    })
                }
            }
        } else if (data['Time Series (1min)'] || data['Time Series (5min)']) {
            // Alpha Vantage format
            var timeSeriesKeys = Object.keys(data)
            var timeSeries = data[timeSeriesKeys[0]] // Get the time series object
            var timeSeriesEntries = Object.keys(timeSeries)
            
            for (var k = 0; k < timeSeriesEntries.length; k++) {
                var timestamp = timeSeriesEntries[k]
                var values = timeSeries[timestamp]
                candlesticks.push({
                    timestamp: new Date(timestamp),
                    open: parseFloat(values['1. open']),
                    high: parseFloat(values['2. high']),
                    low: parseFloat(values['3. low']),
                    close: parseFloat(values['4. close']),
                    volume: parseInt(values['5. volume'])
                })
            }
        }
        
        // Sort candlesticks by timestamp
        candlesticks.sort(function(a, b) {
            return a.timestamp - b.timestamp
        })
        
        return candlesticks
    } catch (error) {
        dbgprint('Error parsing candlestick data: ' + error.message)
        return []
    }
}

function getStockProvider() {
    return 'yahoo'
}

function parseStockResponse(jsonString, symbol) {
    return parseYahooFinanceResponse(jsonString, symbol)
}
