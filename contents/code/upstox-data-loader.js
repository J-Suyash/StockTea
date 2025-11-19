/*
 * Upstox API Integration for Indian Equities
 * Provides the same interface as stock-data-loader.js for drop-in replacement
 */

// Try to include a gzip inflater (pako) if available in vendor
try { Qt.include('./vendor/pako_inflate.min.js') } catch (e) { }

function dbgprint(msg) {
    if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
        main.dbgprint('[Upstox] ' + msg)
    } else {
        print('[Upstox] ' + msg)
    }
}

function emitNetworkLog(entry) {
    try {
        if (typeof main !== 'undefined' && typeof main.addNetworkLog === 'function') {
            var e = entry || {}
            e.timestamp = new Date().toISOString()
            main.addNetworkLog(e)
        }
    } catch (e) {
        // Ignore logging errors
    }
}

function fetchStockData(symbol, successCallback, failureCallback) {
    dbgprint('Fetching stock data for symbol: ' + symbol)

    var api = new UpstoxAPI()

    // If caller passed an Upstox instrument_key (contains '|'), use LTP endpoint
    if (typeof symbol === 'string' && symbol.indexOf('|') !== -1) {
        return api.fetchLtpForInstrument(symbol, function (data) {
            try {
                var ltp = extractLtpFromResponse(data)
                if (!ltp || isNaN(ltp)) {
                    // Fallback to Yahoo if LTP missing
                    return fetchYahooFinanceChart(symbol, successCallback, failureCallback)
                }

                var response = {
                    chart: {
                        result: [{
                            meta: {
                                currency: 'INR',
                                symbol: symbol,
                                regularMarketPrice: ltp,
                                regularMarketPreviousClose: ltp
                            },
                            timestamp: [Math.floor(Date.now() / 1000)],
                            indicators: {
                                quote: [{
                                    open: [ltp],
                                    high: [ltp],
                                    low: [ltp],
                                    close: [ltp],
                                    volume: [0]
                                }]
                            }
                        }]
                    }
                }
                successCallback(JSON.stringify(response))
            } catch (error) {
                dbgprint('Error handling LTP response: ' + error.message)
                fetchYahooFinanceChart(symbol, successCallback, failureCallback)
            }
        }, function (err) {
            // On Upstox failure, fallback to Yahoo
            dbgprint('Upstox LTP failed: ' + err)
            fetchYahooFinanceChart(symbol, successCallback, failureCallback)
        })
    }

    // Otherwise, we likely have a plain symbol like 'RELIANCE'. Use Yahoo fallback
    return fetchYahooFinanceChart(symbol, successCallback, failureCallback)
}

function fetchCandlestickData(symbol, timeframe, successCallback, failureCallback) {
    dbgprint('Fetching candlestick data for symbol: ' + symbol + ', timeframe: ' + timeframe)

    var api = new UpstoxAPI()

    // Calculate date range based on timeframe
    var now = new Date()
    var fromDate = new Date()

    switch (timeframe) {
        case '1m':
        case '5m':
        case '15m':
        case '30m':
        case '1h':
            fromDate.setDate(now.getDate() - 1) // 1 day
            break
        case '1d':
            fromDate.setMonth(now.getMonth() - 1) // 1 month
            break
        case '1w':
            fromDate.setMonth(now.getMonth() - 3) // 3 months
            break
        case '1M':
            fromDate.setFullYear(now.getFullYear() - 1) // 1 year
            break
        default:
            fromDate.setMonth(now.getMonth() - 1)
    }

    var fromDateStr = fromDate.toISOString().split('T')[0]
    var toDateStr = now.toISOString().split('T')[0]

    var upstoxSymbol = convertSymbolToUpstoxFormat(symbol)
    var interval = getUpstoxInterval(timeframe)
    var url = api.baseUrl + '/v2/historical-candle/' + upstoxSymbol + '/' + interval + '/' + fromDateStr + '/' + toDateStr

    return api.makeRequest(url, api.getHeaders(), function (data) {
        try {
            var candles = api.parseHistoricalCandles(data, symbol)
            if (candles && candles.length > 0) {
                // Convert to Yahoo Finance format for compatibility
                var response = {
                    chart: {
                        result: [{
                            meta: {
                                currency: 'INR',
                                symbol: symbol
                            },
                            timestamp: candles.map(function (c) { return Math.floor(c.timestamp.getTime() / 1000) }),
                            indicators: {
                                quote: [{
                                    open: candles.map(function (c) { return c.open }),
                                    high: candles.map(function (c) { return c.high }),
                                    low: candles.map(function (c) { return c.low }),
                                    close: candles.map(function (c) { return c.close }),
                                    volume: candles.map(function (c) { return c.volume })
                                }]
                            }
                        }]
                    }
                }
                successCallback(JSON.stringify(response))
            } else {
                failureCallback('No chart data available')
            }
        } catch (error) {
            dbgprint('Error parsing Upstox historical data: ' + error.message)
            failureCallback('Parse error: ' + error.message)
        }
    }, failureCallback)
}

// v3 historical candles (unauthenticated fallback)
function fetchHistoricalCandlesV3(instrumentKey, timeframe, successCallback, failureCallback) {
    dbgprint(`Fetching historical candles v3 for: ${instrumentKey}, timeframe: ${timeframe}`)

    var api = new UpstoxAPI()
    var range = computeV3DateRange(timeframe)
    var tf = mapToV3Interval(timeframe)
    var url = `${api.baseUrl}/v3/historical-candle/${encodeURIComponent(instrumentKey)}/${tf.unit}/${tf.multiplier}/${range.from}/${range.to}`
    return api.makeRequestNoAuthV3(url, function (data) { successCallback(data) }, failureCallback)
}

function parseStockResponse(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)

        if (!data.chart || !data.chart.result || data.chart.result.length === 0) {
            throw new Error('Invalid response data')
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
        var previousPrice = quotes.close[latestIndex - 1] || meta.regularMarketPreviousClose || currentPrice
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
            currency: meta.currency || 'INR',
            provider: 'upstox'
        }
    } catch (error) {
        dbgprint('Error parsing stock response: ' + error.message)
        return null
    }
}

function parseCandlestickData(jsonString, symbol) {
    try {
        var data = JSON.parse(jsonString)
        var candlesticks = []

        // Handle different API response formats
        if (data.chart && data.chart.result) {
            // Yahoo Finance format (converted from Upstox)
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
        }

        // Sort candlesticks by timestamp
        candlesticks.sort(function (a, b) {
            return a.timestamp - b.timestamp
        })

        return candlesticks
    } catch (error) {
        dbgprint('Error parsing candlestick data: ' + error.message)
        return []
    }
}

function getStockProvider() {
    return 'upstox'
}

function UpstoxAPI() {
    this.baseUrl = 'https://api.upstox.com'
    this.apiKey = plasmoid.configuration.upstoxApiKey || ''
    this.accessToken = plasmoid.configuration.upstoxAccessToken || ''
    this.apiSecret = plasmoid.configuration.upstoxApiSecret || ''
    this._instruments = null
    this._lastInstrumentsLoadedAt = 0
}

UpstoxAPI.prototype.getHeaders = function () {
    return {
        'Accept': 'application/json',
        'Api-Key': this.apiKey,
        'Authorization': 'Bearer ' + this.accessToken
    }
}

UpstoxAPI.prototype.getAuthHeaders = function () {
    return {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Api-Key': this.apiKey,
        'X-Api-Secret': this.apiSecret
    }
}

UpstoxAPI.prototype.fetchInstruments = function (successCallback, failureCallback) {
    var self = this
    dbgprint("Fetching instruments from Upstox API")

    // Check cache first (6 hour TTL)
    if (self._instruments && (Date.now() - self._lastInstrumentsLoadedAt) < 6 * 60 * 60 * 1000) {
        dbgprint("Using cached instruments: " + self._instruments.length + " instruments")
        successCallback(self._instruments)
        return null
    }

    // Skip gzip file due to XMLHttpRequest file access restrictions in plasmoidviewer
    // Go directly to CSV endpoint which works without special permissions
    dbgprint("Skipping gzip file, using CSV API endpoint directly")
    return this.fetchInstrumentsFromAPI(successCallback, failureCallback)
}

UpstoxAPI.prototype._fetchInstrumentsGz = function (jsonUrl, successCallback, failureCallback) {
    var self = this
    dbgprint("Attempting instruments JSON (gz): " + jsonUrl)
    return this.fetchInstrumentsJSON(jsonUrl, function (data) {
        try {
            var parsed = self.parseInstrumentsJSON(data)
            self._instruments = parsed
            self._lastInstrumentsLoadedAt = Date.now()
            dbgprint("Successfully parsed " + parsed.length + " instruments from JSON (gz)")
            successCallback(parsed)
        } catch (e) {
            dbgprint("Error parsing gz instruments JSON: " + e.message)
            // Final fallback: try API endpoint (CSV)
            self.fetchInstrumentsFromAPI(successCallback, failureCallback)
        }
    }, function (err) {
        // Final fallback: try API endpoint (CSV)
        self.fetchInstrumentsFromAPI(successCallback, failureCallback)
    })
}

UpstoxAPI.prototype.fetchInstrumentsJSON = function (jsonUrl, successCallback, failureCallback) {
    var self = this
    var xhr = new XMLHttpRequest()
    var startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: jsonUrl })
    xhr.open('GET', jsonUrl)
    xhr.timeout = (typeof plasmoid !== 'undefined' && plasmoid.configuration && plasmoid.configuration.apiTimeout) ? plasmoid.configuration.apiTimeout : 30000
    // Fetch as arraybuffer to manually gunzip
    xhr.responseType = 'arraybuffer'
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            var ok = xhr.status === 200
            emitNetworkLog({ phase: 'load', method: 'GET', url: jsonUrl, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.response ? xhr.response.byteLength : 0) })
            if (ok) {
                try {
                    var buf = xhr.response
                    if (!buf || !buf.byteLength) throw new Error('Empty gzip payload')
                    // Use pako or Qt.inflateData if available
                    var gunzipped
                    if (typeof pako !== 'undefined' && typeof pako.inflate === 'function') {
                        gunzipped = pako.inflate(new Uint8Array(buf), { to: 'string' })
                    } else if (typeof Qt !== 'undefined' && typeof Qt.inflateData === 'function') {
                        gunzipped = Qt.inflateData(buf)
                    } else {
                        throw new Error('No gzip inflater available')
                    }
                    var data = JSON.parse(gunzipped)
                    var parsed = self.parseInstrumentsJSON(data)
                    self._instruments = parsed
                    self._lastInstrumentsLoadedAt = Date.now()
                    successCallback(parsed)
                } catch (e) {
                    dbgprint('Gzip instruments error: ' + e.message)
                    // Fallback to API endpoint (CSV)
                    self.fetchInstrumentsFromAPI(successCallback, failureCallback)
                }
            } else {
                failureCallback('Failed to download instruments JSON')
            }
        }
    }
    xhr.onerror = function () {
        emitNetworkLog({ phase: 'error', method: 'GET', url: jsonUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Network error')
    }
    xhr.ontimeout = function () {
        emitNetworkLog({ phase: 'timeout', method: 'GET', url: jsonUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Request timeout')
    }
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.fetchInstrumentsJSONText = function (jsonUrl, successCallback, failureCallback) {
    var xhr = new XMLHttpRequest()
    var startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: jsonUrl })
    xhr.open('GET', jsonUrl)
    xhr.timeout = (typeof plasmoid !== 'undefined' && plasmoid.configuration && plasmoid.configuration.apiTimeout) ? plasmoid.configuration.apiTimeout : 15000
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            var ok = xhr.status === 200
            emitNetworkLog({ phase: 'load', method: 'GET', url: jsonUrl, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.responseText ? xhr.responseText.length : 0) })
            if (ok) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    successCallback(data)
                } catch (e) {
                    failureCallback('Invalid JSON')
                }
            } else {
                failureCallback('HTTP ' + xhr.status)
            }
        }
    }
    xhr.onerror = function () { emitNetworkLog({ phase: 'error', method: 'GET', url: jsonUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt }); failureCallback('Network error') }
    xhr.ontimeout = function () { emitNetworkLog({ phase: 'timeout', method: 'GET', url: jsonUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt }); failureCallback('Timeout') }
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.fetchInstrumentsFromAPI = function (successCallback, failureCallback) {
    var self = this
    dbgprint("Fetching instruments from public CSV endpoint")

    // Use the complete instruments CSV - publicly accessible, no auth required
    // CSV is uncompressed and works without gzip decompression
    var publicCsvUrl = 'https://assets.upstox.com/market-quote/instruments/exchange/complete.csv'

    dbgprint("Public CSV URL: " + publicCsvUrl)

    return this.fetchInstrumentsCSV(publicCsvUrl, function (text) {
        try {
            dbgprint("Downloaded " + text.length + " characters, parsing CSV...")
            var parsed = self.parseInstrumentsCSV(text)
            self._instruments = parsed
            self._lastInstrumentsLoadedAt = Date.now()
            dbgprint("Successfully parsed " + parsed.length + " instruments from CSV")
            successCallback(parsed)
        } catch (e) {
            dbgprint("Error parsing CSV: " + e.message)
            failureCallback('Failed to parse instruments CSV: ' + e.message)
        }
    }, function (err) {
        dbgprint("Failed to fetch CSV: " + err)
        failureCallback('Failed to fetch instruments: ' + err)
    })
}

UpstoxAPI.prototype.fetchInstrumentsCSV = function (csvUrl, successCallback, failureCallback) {
    var xhr = new XMLHttpRequest()
    var startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: csvUrl })
    xhr.open('GET', csvUrl)
    xhr.timeout = plasmoid.configuration.apiTimeout || 20000
    xhr.onreadystatechange = function () {
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
    xhr.onerror = function () {
        emitNetworkLog({ phase: 'error', method: 'GET', url: csvUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Network error')
    }
    xhr.ontimeout = function () {
        emitNetworkLog({ phase: 'timeout', method: 'GET', url: csvUrl, status: xhr.status, ok: false, durationMs: Date.now() - startedAt })
        failureCallback('Request timeout')
    }
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.parseInstrumentsJSON = function (data) {
    dbgprint("Parsing instruments JSON, array length: " + (data ? data.length : 0))

    if (!data || !Array.isArray(data)) {
        dbgprint("Invalid JSON data format")
        return []
    }

    var out = []
    for (var i = 0; i < data.length; i++) {
        var item = data[i]

        // Filter for equity instruments only (NSE_EQ, BSE_EQ)
        if (item.segment !== 'NSE_EQ' && item.segment !== 'BSE_EQ') {
            continue
        }

        var symbol = item.trading_symbol || ''
        var name = item.name || item.short_name || symbol
        var exchange = item.exchange || ''
        var instrument_key = item.instrument_key || ''
        var isin = item.isin || ''
        var instrument_type = item.instrument_type || ''

        if (!symbol) {
            continue
        }

        var instrument = {
            symbol: symbol,
            name: name,
            exchange: exchange,
            instrument_key: instrument_key,
            isin: isin,
            instrument_type: instrument_type,
            segment: item.segment
        }
        out.push(instrument)

        if (i < 5) { // Log first few instruments for debugging
            dbgprint("Parsed instrument " + i + ": " + JSON.stringify(instrument))
        }
    }

    dbgprint("Total equity instruments parsed: " + out.length)
    return out
}

UpstoxAPI.prototype.parseInstrumentsCSV = function (text) {
    dbgprint("Parsing instruments CSV, text length: " + (text ? text.length : 0))

    var lines = (text || '').split(/\r?\n/)
    if (lines.length === 0) {
        dbgprint("No lines in CSV text")
        return []
    }

    var header = lines[0].split(',')
    dbgprint("CSV header: " + header.join(', '))

    var idx = {}
    for (var i = 0; i < header.length; i++) {
        var headerName = header[i].trim()
        idx[headerName] = i
        dbgprint("Header index " + i + ": " + headerName + " -> " + i)
    }

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

        if (!symbol) {
            dbgprint("Skipping line " + j + " - no symbol found")
            continue
        }

        var instrument = { symbol: symbol, name: name, exchange: exchange, instrument_key: instrument_key, isin: isin }
        out.push(instrument)

        if (j <= 5) { // Log first few instruments for debugging
            dbgprint("Parsed instrument " + j + ": " + JSON.stringify(instrument))
        }
    }

    dbgprint("Total instruments parsed: " + out.length)
    return out
}

UpstoxAPI.prototype.searchTradableSymbols = function (query, successCallback, failureCallback) {
    var self = this
    var q = String(query || '').trim().toUpperCase()
    if (!q) { successCallback([]); return null }
    var filterAndReturn = function (list) {
        try {
            var results = list.filter(function (it) {
                return (it.symbol && it.symbol.toUpperCase().indexOf(q) !== -1) ||
                    (it.name && it.name.toUpperCase().indexOf(q) !== -1)
            }).slice(0, 25)
            successCallback(results)
        } catch (e) {
            dbgprint("Search failed: " + e.message)
            failureCallback('Search failed')
        }
    }
    if (self._instruments) {
        filterAndReturn(self._instruments);
        return null
    }
    return self.fetchInstruments(function (list) { filterAndReturn(list) }, failureCallback)
}

UpstoxAPI.prototype.fetchMarketQuote = function (symbol, successCallback, failureCallback) {
    dbgprint('Fetching market quote from Upstox for: ' + symbol)

    // Convert Indian stock symbol to Upstox format
    const upstoxSymbol = convertSymbolToUpstoxFormat(symbol)
    const url = `${this.baseUrl}/v2/quote/${upstoxSymbol}`

    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchHistoricalCandles = function (symbol, timeframe, fromDate, toDate, successCallback, failureCallback) {
    dbgprint(`Fetching historical candles from Upstox for: ${symbol}, timeframe: ${timeframe}`)

    const upstoxSymbol = convertSymbolToUpstoxFormat(symbol)
    const interval = getUpstoxInterval(timeframe)
    const url = `${this.baseUrl}/v2/historical-candle/${upstoxSymbol}/${interval}/${fromDate}/${toDate}`

    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchPortfolioPositions = function (successCallback, failureCallback) {
    dbgprint('Fetching portfolio positions from Upstox')

    const url = `${this.baseUrl}/v2/portfolio/long-term-positions`

    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.fetchFullMarketQuotes = function (symbols, successCallback, failureCallback) {
    dbgprint('Fetching full market quotes from Upstox for: ' + symbols.join(', '))

    // Upstox full market quotes endpoint (v2) expects instrument_keys for best results.
    const symbolList = symbols.join(',')
    const url = `${this.baseUrl}/v2/market-quote/full?instrument_keys=${encodeURIComponent(symbolList)}`

    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

// Fetch LTP for a single instrument_key
UpstoxAPI.prototype.fetchLtpForInstrument = function (instrumentKey, successCallback, failureCallback) {
    const url = `${this.baseUrl}/v2/market-quote/ltp?instrument_key=${encodeURIComponent(instrumentKey)}`
    return this.makeRequest(url, this.getHeaders(), successCallback, failureCallback)
}

UpstoxAPI.prototype.makeRequest = function (url, headers, successCallback, failureCallback) {
    const xhr = new XMLHttpRequest()
    xhr.timeout = (typeof plasmoid !== 'undefined' && plasmoid.configuration && plasmoid.configuration.apiTimeout) ? plasmoid.configuration.apiTimeout : 15000

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

// Minimal v3 request without Authorization header (as per user-provided example)
UpstoxAPI.prototype.makeRequestNoAuthV3 = function (url, successCallback, failureCallback) {
    const xhr = new XMLHttpRequest()
    xhr.timeout = plasmoid.configuration.apiTimeout || 15000
    dbgprint('Upstox v3 Request: ' + url)
    const startedAt = Date.now()
    emitNetworkLog({ phase: 'open', method: 'GET', url: url })
    xhr.open('GET', url)
    xhr.setRequestHeader('Accept', 'application/json')
    xhr.setRequestHeader('Content-Type', 'application/json')
    xhr.ontimeout = () => { emitNetworkLog({ phase: 'timeout', method: 'GET', url: url, status: xhr.status, ok: false, durationMs: Date.now() - startedAt }); failureCallback('Request timeout') }
    xhr.onerror = () => { emitNetworkLog({ phase: 'error', method: 'GET', url: url, status: xhr.status, ok: false, durationMs: Date.now() - startedAt }); failureCallback('Network error: ' + xhr.status) }
    xhr.onload = () => {
        const ok = xhr.status === 200
        emitNetworkLog({ phase: 'load', method: 'GET', url: url, status: xhr.status, ok: ok, durationMs: Date.now() - startedAt, size: (xhr.responseText ? xhr.responseText.length : 0) })
        if (ok) {
            try { successCallback(JSON.parse(xhr.responseText)) } catch (e) { failureCallback('Invalid JSON response') }
        } else { failureCallback('API error: ' + xhr.status) }
    }
    xhr.send()
    return xhr
}

UpstoxAPI.prototype.parseMarketQuote = function (data, symbol) {
    try {
        if (!data) {
            throw new Error('Empty market quote response')
        }

        // Support multiple shapes: single LTP, array of quotes, or keyed objects
        let quoteData = null
        if (data.data) {
            if (Array.isArray(data.data) && data.data.length) {
                quoteData = data.data[0]
            } else if (typeof data.data === 'object') {
                // Sometimes returns { ltp: number, ohlc: {...}, last_price: ... }
                if ('ltp' in data.data || 'last_price' in data.data) {
                    quoteData = data.data
                } else {
                    // Try first value
                    const values = Object.values(data.data)
                    if (values && values.length) quoteData = values[0]
                }
            }
        }
        // Fallback to root
        if (!quoteData && (data.ltp || data.last_price)) {
            quoteData = data
        }
        if (!quoteData) throw new Error('No quote found in response')

        const ltp = Number(quoteData.ltp || quoteData.last_price || 0)
        const ohlc = quoteData.ohlc || {}
        const open = Number(ohlc.open || ltp)
        const high = Number(ohlc.high || ltp)
        const low = Number(ohlc.low || ltp)
        const prevClose = Number(quoteData.close || quoteData.closed_price || ohlc.close || ltp)
        const dayChange = ltp - prevClose
        const dayChangePercent = prevClose > 0 ? (dayChange / prevClose) * 100 : 0

        return {
            symbol: symbol,
            currentPrice: ltp,
            openPrice: open,
            highPrice: high,
            lowPrice: low,
            previousClose: prevClose,
            volume: Number(quoteData.volume || 0),
            timestamp: new Date(quoteData.last_update_time || quoteData.timestamp || Date.now()),
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

UpstoxAPI.prototype.parseHistoricalCandles = function (data, symbol) {
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

// v3 parser
UpstoxAPI.prototype.parseHistoricalCandlesV3 = function (data, symbol) {
    try {
        if (!data || data.status !== 'success' || !data.data) {
            throw new Error('Invalid historical v3 data response')
        }
        const out = []
        const candles = data.data.candles || []
        candles.forEach(c => {
            // Format: [timestampISO, open, high, low, close, volume, oi?]
            out.push({
                timestamp: new Date(c[0]),
                open: Number(c[1]),
                high: Number(c[2]),
                low: Number(c[3]),
                close: Number(c[4]),
                volume: parseInt(c[5] || 0)
            })
        })
        return out.sort((a, b) => a.timestamp - b.timestamp)
    } catch (e) {
        dbgprint('Error parsing Upstox v3 historical candles: ' + e.message)
        return []
    }
}

function mapToV3Interval(timeframe) {
    switch (String(timeframe)) {
        case '1m': return { unit: 'minutes', multiplier: 1 }
        case '5m': return { unit: 'minutes', multiplier: 5 }
        case '15m': return { unit: 'minutes', multiplier: 15 }
        case '30m': return { unit: 'minutes', multiplier: 30 }
        case '1h': return { unit: 'minutes', multiplier: 60 }
        case '1w': return { unit: 'week', multiplier: 1 }
        case '1M': return { unit: 'month', multiplier: 1 }
        case '1d':
        default: return { unit: 'day', multiplier: 1 }
    }
}

function computeV3DateRange(timeframe) {
    const now = new Date()
    const to = new Date(now)
    const from = new Date(now)
    switch (String(timeframe)) {
        case '1m':
        case '5m':
        case '15m':
        case '30m':
        case '1h': from.setDate(now.getDate() - 5); break // ~5 days intraday
        case '1w': from.setFullYear(now.getFullYear() - 1); break
        case '1M': from.setFullYear(now.getFullYear() - 2); break
        case '1d':
        default: from.setFullYear(now.getFullYear() - 1); break
    }
    const iso = d => d.toISOString().slice(0, 10)
    const f = iso(from)
    const t = iso(to)
    return { from: f, to: t }
}

UpstoxAPI.prototype.parsePortfolioPositions = function (data, symbol) {
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

// --------------
// Helpers / Fallbacks
// --------------

function extractLtpFromResponse(data) {
    try {
        if (!data) return 0
        if (data.data) {
            if (typeof data.data === 'object' && !Array.isArray(data.data)) {
                if (typeof data.data.ltp !== 'undefined') return Number(data.data.ltp)
                const first = Object.values(data.data)[0]
                if (first && typeof first.ltp !== 'undefined') return Number(first.ltp)
                if (typeof data.data.last_price !== 'undefined') return Number(data.data.last_price)
            }
            if (Array.isArray(data.data) && data.data.length) {
                const item = data.data[0]
                if (typeof item.ltp !== 'undefined') return Number(item.ltp)
                if (typeof item.last_price !== 'undefined') return Number(item.last_price)
            }
        }
        if (typeof data.ltp !== 'undefined') return Number(data.ltp)
        if (typeof data.last_price !== 'undefined') return Number(data.last_price)
    } catch (e) {
        // ignore
    }
    return 0
}

function convertToYahooFinanceFormat(symbol) {
    // If instrument_key like NSE_EQ|XXXX, derive a best-effort ticker isn't possible reliably.
    if (typeof symbol !== 'string') return ''
    if (symbol.includes('|')) {
        // Fallback: return as-is to avoid mangling; Yahoo may fail, but Upstox path should have been used.
        return symbol
    }
    let s = String(symbol).trim().toUpperCase()
    if (s.endsWith('.NS') || s.endsWith('.BO')) return s
    if (s.endsWith('-EQ')) s = s.slice(0, -3)
    return s + '.NS'
}

function fetchYahooFinanceChart(symbol, successCallback, failureCallback) {
    try {
        const ySymbol = convertToYahooFinanceFormat(symbol)
        const url = 'https://query1.finance.yahoo.com/v8/finance/chart/' + encodeURIComponent(ySymbol)
        const xhr = new XMLHttpRequest()
        xhr.timeout = plasmoid.configuration.apiTimeout || 15000
        dbgprint('Yahoo Finance GET: ' + url)
        xhr.open('GET', url)
        xhr.setRequestHeader('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64) StockPortfolioWidget/2.0')
        xhr.onerror = function () { failureCallback('Network error') }
        xhr.ontimeout = function () { failureCallback('Request timeout') }
        xhr.onload = function () {
            if (xhr.status !== 200) {
                return failureCallback('HTTP error: ' + xhr.status)
            }
            successCallback(xhr.responseText)
        }
        xhr.send()
        return xhr
    } catch (e) {
        failureCallback('Yahoo fetch error: ' + e.message)
        return null
    }
}
// v3 LTP without auth; return minimal object-like response
UpstoxAPI.prototype.fetchLtpV3NoAuth = function (instrumentKey, successCallback, failureCallback) {
    const url = `${this.baseUrl}/v3/market-quote/ltp?instrument_key=${encodeURIComponent(instrumentKey)}`
    return this.makeRequestNoAuthV3(url, successCallback, failureCallback)
}
