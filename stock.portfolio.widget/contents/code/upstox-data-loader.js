/*
 * Upstox API Integration for Indian Equities
 * Primary data source with fallback support
 * Based on Context7 Upstox API documentation
 */

function UpstoxAPI() {
    this.baseUrl = 'https://api.upstox.com'
    this.apiKey = plasmoid.configuration.upstoxApiKey || ''
    this.accessToken = plasmoid.configuration.upstoxAccessToken || ''
    this.apiSecret = plasmoid.configuration.upstoxApiSecret || ''
}

UpstoxAPI.prototype.getHeaders = function() {
    return {
        'Accept': 'application/json',
        'Api-Key': this.apiKey,
        'Authorization': 'Bearer ' + this.accessToken
    }
}

UpstoxAPI.prototype.getAuthHeaders = function() {
    return {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Api-Key': this.apiKey,
        'X-Api-Secret': this.apiSecret
    }
}

UpstoxAPI.prototype.fetchMarketQuote = function(symbol, successCallback, failureCallback) {
    dbgprint('Fetching market quote from Upstox for: ' + symbol)
    
    // Convert Indian stock symbol to Upstox format
    const upstoxSymbol = convertSymbolToUpstoxFormat(symbol)
    const url = `${this.baseUrl}/v2/quote/${upstoxSymbol}`
    
    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchHistoricalCandles = function(symbol, timeframe, fromDate, toDate, successCallback, failureCallback) {
    dbgprint(`Fetching historical candles from Upstox for: ${symbol}, timeframe: ${timeframe}`)
    
    const upstoxSymbol = convertSymbolToUpstoxFormat(symbol)
    const interval = getUpstoxInterval(timeframe)
    const url = `${this.baseUrl}/v2/historical-candle/${upstoxSymbol}/${interval}/${fromDate}/${toDate}`
    
    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchPortfolioPositions = function(successCallback, failureCallback) {
    dbgprint('Fetching portfolio positions from Upstox')
    
    const url = `${this.baseUrl}/v2/portfolio/long-term-positions`
    
    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchFullMarketQuotes = function(symbols, successCallback, failureCallback) {
    dbgprint('Fetching full market quotes from Upstox for: ' + symbols.join(', '))
    
    const symbolList = symbols.map(convertSymbolToUpstoxFormat).join(',')
    const url = `${this.baseUrl}/market-quote/quotes/full?symbols=${encodeURIComponent(symbolList)}`
    
    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.makeRequest = function(url, headers, successCallback, failureCallback) {
    const xhr = new XMLHttpRequest()
    xhr.timeout = plasmoid.configuration.apiTimeout || 15000
    
    dbgprint('Upstox API Request: ' + url)
    xhr.open('GET', url)
    
    // Set headers
    Object.keys(headers).forEach(key => {
        xhr.setRequestHeader(key, headers[key])
    })
    
    xhr.ontimeout = () => {
        dbgprint('Upstox API timeout')
        failureCallback('Request timeout')
    }
    
    xhr.onerror = (event) => {
        dbgprint('Upstox API error: ' + xhr.status)
        failureCallback('Network error: ' + xhr.status)
    }
    
    xhr.onload = () => {
        if (xhr.status === 200) {
            try {
                const data = JSON.parse(xhr.responseText)
                successCallback(data)
            } catch (error) {
                dbgprint('Invalid JSON response from Upstox')
                failureCallback('Invalid JSON response')
            }
        } else if (xhr.status === 401) {
            dbgprint('Upstox authentication failed')
            failureCallback('Authentication failed')
        } else if (xhr.status === 429) {
            dbgprint('Upstox rate limit exceeded')
            failureCallback('Rate limit exceeded')
        } else {
            dbgprint('Upstox API error: ' + xhr.status + ' - ' + xhr.responseText)
            failureCallback('API error: ' + xhr.status)
        }
    }
    
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.parseMarketQuote = function(data, symbol) {
    try {
        if (!data || !data.data) {
            throw new Error('Invalid market quote response')
        }
        
        const quoteData = data.data
        const ltp = quoteData.ltp || 0
        const open = quoteData.ohlc ? quoteData.ohlc.open : ltp
        const high = quoteData.ohlc ? quoteData.ohlc.high : ltp
        const low = quoteData.ohlc ? quoteData.ohlc.low : ltp
        const prevClose = quoteData.closed_price || ltp
        const dayChange = ltp - prevClose
        const dayChangePercent = prevClose > 0 ? (dayChange / prevClose) * 100 : 0
        
        return {
            symbol: symbol,
            currentPrice: ltp,
            openPrice: open,
            highPrice: high,
            lowPrice: low,
            previousClose: prevClose,
            volume: quoteData.volume || 0,
            timestamp: new Date(quoteData.last_update_time || Date.now()),
            dayChange: dayChange,
            dayChangePercent: dayChangePercent,
            currency: 'INR',
            provider: 'upstox',
            marketCap: quoteData.market_cap || null,
            peRatio: quoteData.pe || null
        }
    } catch (error) {
        dbgprint('Error parsing Upstox market quote: ' + error.message)
        return null
    }
}

UpstoxAPI.prototype.parseHistoricalCandles = function(data, symbol) {
    try {
        if (!data || !data.success || !data.data) {
            throw new Error('Invalid historical data response')
        }
        
        const candles = []
        const candleData = data.data.candles || []
        
        candleData.forEach(candle => {
            candles.push({
                timestamp: new Date(candle[0]),
                open: parseFloat(candle[1]),
                high: parseFloat(candle[2]),
                low: parseFloat(candle[3]),
                close: parseFloat(candle[4]),
                volume: parseInt(candle[5])
            })
        })
        
        return candles.sort((a, b) => a.timestamp - b.timestamp)
    } catch (error) {
        dbgprint('Error parsing Upstox historical candles: ' + error.message)
        return []
    }
}

UpstoxAPI.prototype.parsePortfolioPositions = function(data, symbol) {
    try {
        if (!data || !data.success || !data.data) {
            throw new Error('Invalid portfolio data response')
        }
        
        const positions = []
        const positionData = data.data
        
        positionData.forEach(position => {
            positions.push({
                symbol: position.trading_symbol || position.tradingsymbol || '',
                exchange: position.exchange || 'NSE',
                quantity: parseInt(position.net_quantity || position.netQty || 0),
                averagePrice: parseFloat(position.average_price || position.avgPrice || 0),
                currentPrice: parseFloat(position.ltp || position.last_price || 0),
                totalValue: parseFloat(position.ltp || 0) * parseInt(position.net_quantity || 0),
                totalCost: parseFloat(position.average_price || 0) * parseInt(position.net_quantity || 0),
                unrealizedPL: parseFloat(position.unrealized_pnl || 0),
                realizedPL: parseFloat(position.realized_pnl || 0),
                dayChange: parseFloat(position.day_change || 0),
                dayChangePercent: parseFloat(position.day_change_percent || 0)
            })
        })
        
        return positions
    } catch (error) {
        dbgprint('Error parsing Upstox portfolio positions: ' + error.message)
        return []
    }
}

// Utility functions for Upstox integration
function convertSymbolToUpstoxFormat(symbol) {
    // Handle different Indian stock symbol formats
    if (symbol.includes('NSE_EQ|') || symbol.includes('BSE_EQ|')) {
        return symbol
    }
    
    if (symbol.includes('-EQ')) {
        return symbol
    }
    
    if (symbol.includes('.')) {
        // Convert Yahoo Finance format (e.g., RELIANCE.NS)
        const cleanSymbol = symbol.split('.')[0]
        return `${cleanSymbol}-EQ`
    }
    
    // Default: assume NSE equity
    return `${symbol}-EQ`
}

function getUpstoxInterval(timeframe) {
    const mapping = {
        '1m': '1minute',
        '5m': '5minute',
        '15m': '15minute',
        '30m': '30minute',
        '1h': '1hour',
        '1d': '1day',
        '1w': '1week',
        '1M': '1month'
    }
    return mapping[timeframe] || '1day'
}

function getUpstoxTimeframeFromInterval(interval) {
    const mapping = {
        '1minute': '1m',
        '5minute': '5m',
        '15minute': '15m',
        '30minute': '30m',
        '1hour': '1h',
        '1day': '1d',
        '1week': '1w',
        '1month': '1M'
    }
    return mapping[interval] || '1d'
}