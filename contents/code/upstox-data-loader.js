/*
 * Upstox API Integration for Indian Equities
 * NOTE: This module is NOT currently used in the main application.
 * API key is not required - application uses stock-data-loader.js instead.
 * This file is kept for future reference but can be removed if not needed.
 */

function UpstoxAPI() {
    this.baseUrl = 'https://api.upstox.com'
    this.apiKey = plasmoid.configuration.upstoxApiKey || ''
    this.accessToken = plasmoid.configuration.upstoxAccessToken || ''
    this.apiSecret = plasmoid.configuration.upstoxApiSecret || ''
    this._instruments = null
    this._lastInstrumentsLoadedAt = 0
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

UpstoxAPI.prototype.fetchInstruments = function(successCallback, failureCallback) {
    var self = this
    if (self._instruments && (Date.now() - self._lastInstrumentsLoadedAt) < 6 * 60 * 60 * 1000) {
        successCallback(self._instruments)
        return null
    }
    var url = this.baseUrl + '/v2/instruments'
    return this.makeRequest(url, this.getHeaders(), function(resp) {
        try {
            if (resp && resp.data && resp.data.csv_file_download_url) {
                self.fetchInstrumentsCSV(resp.data.csv_file_download_url, function(text) {
                    var parsed = self.parseInstrumentsCSV(text)
                    self._instruments = parsed
                    self._lastInstrumentsLoadedAt = Date.now()
                    successCallback(parsed)
                }, failureCallback)
                return
            }
            if (typeof resp === 'string' && resp.indexOf('instrument_key') !== -1) {
                var parsed2 = self.parseInstrumentsCSV(resp)
                self._instruments = parsed2
                self._lastInstrumentsLoadedAt = Date.now()
                successCallback(parsed2)
                return
            }
            failureCallback('Unexpected instruments response')
        } catch (e) {
            failureCallback('Failed to process instruments')
        }
    }, failureCallback)
}

UpstoxAPI.prototype.fetchInstrumentsCSV = function(csvUrl, successCallback, failureCallback) {
    var xhr = new XMLHttpRequest()
    var startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: csvUrl })
    xhr.open('GET', csvUrl)
    xhr.timeout = plasmoid.configuration.apiTimeout || 20000
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            var ok = xhr.status === 200
            emitNetworkLog({ phase: 'load', method: 'GET', url: csvUrl, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.responseText ? xhr.responseText.length : 0) })
            if (ok) {
                successCallback(xhr.responseText)
            } else {
                failureCallback('Failed to download instruments CSV')
            }
        }
    }
    xhr.onerror = function() {
        emitNetworkLog({ phase: 'error', method: 'GET', url: csvUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Network error')
    }
    xhr.ontimeout = function() {
        emitNetworkLog({ phase: 'timeout', method: 'GET', url: csvUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Request timeout')
    }
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.parseInstrumentsCSV = function(text) {
    var lines = (text || '').split(/\r?\n/)
    if (lines.length === 0) return []
    var header = lines[0].split(',')
    var idx = {}
    for (var i = 0; i < header.length; i++) idx[header[i].trim()] = i
    var out = []
    for (var j = 1; j < lines.length; j++) {
        var line = lines[j]
        if (!line) continue
        var cols = line.split(',')
        var symbol = cols[idx.trading_symbol] || cols[idx.tradingsymbol] || ''
        var name = cols[idx.name] || ''
        var exchange = cols[idx.exchange] || ''
        var instrument_key = cols[idx.instrument_key] || ''
        var isin = cols[idx.isin] || ''
        if (!symbol) continue
        out.push({ symbol: symbol, name: name, exchange: exchange, instrument_key: instrument_key, isin: isin })
    }
    return out
}

UpstoxAPI.prototype.searchTradableSymbols = function(query, successCallback, failureCallback) {
    var self = this
    var q = String(query || '').trim().toUpperCase()
    if (!q) { successCallback([]); return null }
    var filterAndReturn = function(list) {
        try {
            var results = list.filter(function(it) {
                return (it.symbol && it.symbol.toUpperCase().indexOf(q) !== -1) || (it.name && it.name.toUpperCase().indexOf(q) !== -1)
            }).slice(0, 25)
            successCallback(results)
        } catch (e) { failureCallback('Search failed') }
    }
    if (self._instruments) { filterAndReturn(self._instruments); return null }
    return self.fetchInstruments(function(list) { filterAndReturn(list) }, failureCallback)
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
    const startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: url })
    xhr.open('GET', url)
    
    // Set headers
    Object.keys(headers).forEach(key => {
        xhr.setRequestHeader(key, headers[key])
    })
    
    xhr.ontimeout = () => {
        dbgprint('Upstox API timeout')
        emitNetworkLog({ phase: 'timeout', method: 'GET', url: url, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Request timeout')
    }
    
    xhr.onerror = (event) => {
        dbgprint('Upstox API error: ' + xhr.status)
        emitNetworkLog({ phase: 'error', method: 'GET', url: url, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Network error: ' + xhr.status)
    }
    
    xhr.onload = () => {
        const ok = xhr.status === 200
        emitNetworkLog({ phase: 'load', method: 'GET', url: url, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.responseText ? xhr.responseText.length : 0) })
        if (ok) {
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

function emitNetworkLog(entry) {
    try {
        if (typeof main !== 'undefined' && typeof main.addNetworkLog === 'function') {
            var e = entry || {}
            e.timestamp = new Date().toISOString()
            main.addNetworkLog(e)
        }
    } catch (e) {}
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