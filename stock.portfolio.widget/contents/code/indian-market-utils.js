/*
 * Indian Market Utilities
 * Handles Indian stock market specific functionality
 * Market hours, holidays, symbol validation, etc.
 */

function IndianMarketUtils() {
    this.marketStartHour = 9
    this.marketStartMinute = 15
    this.marketEndHour = 15
    this.marketEndMinute = 30
    this.timezone = 'Asia/Calcutta'
}

IndianMarketUtils.prototype.isMarketOpen = function() {
    if (!plasmoid.configuration.indianMarketHours) {
        return true // Allow data updates even outside market hours
    }
    
    const now = new Date()
    const istTime = this.convertToIST(now)
    
    // Check if it's a weekday (Monday = 1, Friday = 5)
    const dayOfWeek = istTime.getDay()
    if (dayOfWeek === 0 || dayOfWeek === 6) {
        return false // Weekend
    }
    
    // Check if it's a holiday
    if (this.isHoliday(istTime)) {
        return false
    }
    
    // Check market hours
    const marketStart = new Date(istTime)
    marketStart.setHours(this.marketStartHour, this.marketStartMinute, 0, 0)
    
    const marketEnd = new Date(istTime)
    marketEnd.setHours(this.marketEndHour, this.marketEndMinute, 0, 0)
    
    return istTime >= marketStart && istTime <= marketEnd
}

IndianMarketUtils.prototype.convertToIST = function(utcDate) {
    // Convert UTC to IST (UTC+5:30)
    const istOffset = 5.5 * 60 * 60 * 1000 // 5.5 hours in milliseconds
    return new Date(utcDate.getTime() + istOffset)
}

IndianMarketUtils.prototype.isHoliday = function(date) {
    if (!plasmoid.configuration.checkHolidays) {
        return false
    }
    
    try {
        const holidays = JSON.parse(plasmoid.configuration.regionalHolidays || '[]')
        const dateString = date.toISOString().split('T')[0] // YYYY-MM-DD format
        
        return holidays.includes(dateString)
    } catch (error) {
        dbgprint('Error checking holidays: ' + error.message)
        return false
    }
}

IndianMarketUtils.prototype.getNextMarketOpen = function() {
    const now = new Date()
    let nextOpen = new Date(now)
    
    // Move to next day
    nextOpen.setDate(nextOpen.getDate() + 1)
    nextOpen.setHours(this.marketStartHour, this.marketStartMinute, 0, 0)
    
    // Skip weekends
    while (nextOpen.getDay() === 0 || nextOpen.getDay() === 6) {
        nextOpen.setDate(nextOpen.getDate() + 1)
    }
    
    // Skip holidays
    while (this.isHoliday(nextOpen)) {
        nextOpen.setDate(nextOpen.getDate() + 1)
        // Skip weekends after holidays
        while (nextOpen.getDay() === 0 || nextOpen.getDay() === 6) {
            nextOpen.setDate(nextOpen.getDate() + 1)
        }
    }
    
    return nextOpen
}

IndianMarketUtils.prototype.getTimeUntilMarketOpen = function() {
    const now = new Date()
    
    if (this.isMarketOpen()) {
        return 0
    }
    
    const nextOpen = this.getNextMarketOpen()
    return nextOpen.getTime() - now.getTime()
}

IndianMarketUtils.prototype.getMarketStatusText = function() {
    if (this.isMarketOpen()) {
        return 'Market Open'
    }
    
    const timeUntilOpen = this.getTimeUntilMarketOpen()
    const hoursUntilOpen = Math.floor(timeUntilOpen / (1000 * 60 * 60))
    const minutesUntilOpen = Math.floor((timeUntilOpen % (1000 * 60 * 60)) / (1000 * 60))
    
    if (hoursUntilOpen > 0) {
        return `Market Closed - Opens in ${hoursUntilOpen}h ${minutesUntilOpen}m`
    } else if (minutesUntilOpen > 0) {
        return `Market Closed - Opens in ${minutesUntilOpen}m`
    } else {
        return 'Market Closed'
    }
}

IndianMarketUtils.prototype.validateIndianSymbol = function(symbol) {
    const errors = []
    
    if (!symbol || symbol.trim() === '') {
        errors.push('Symbol is required')
        return { isValid: false, errors: errors }
    }
    
    const cleanSymbol = symbol.trim().toUpperCase()
    
    // Check for valid Indian stock symbol patterns
    const validPatterns = [
        /^[A-Z]{2,10}$/, // Standard symbols like RELIANCE, TCS
        /^[A-Z]{2,10}-EQ$/, // Exchange format like RELIANCE-EQ
        /^NSE_EQ\|[A-Z0-9]+$/, // Upstox NSE format
        /^BSE_EQ\|[A-Z0-9]+$/, // Upstox BSE format
        /^[A-Z]{2,10}\.(NS|BO)$/ // Yahoo Finance format
    ]
    
    const isValidPattern = validPatterns.some(pattern => pattern.test(cleanSymbol))
    
    if (!isValidPattern) {
        errors.push('Invalid Indian stock symbol format')
    }
    
    // Check for reserved/invalid symbols
    const invalidSymbols = ['CASH', 'FUT', 'OPT', 'FUTSTK', 'FUTIDX', 'OPTSTK', 'OPTIDX']
    if (invalidSymbols.includes(cleanSymbol)) {
        errors.push('Invalid symbol type - use equity symbols only')
    }
    
    return {
        isValid: errors.length === 0,
        errors: errors,
        normalizedSymbol: cleanSymbol,
        suggestedFormat: this.suggestSymbolFormat(cleanSymbol)
    }
}

IndianMarketUtils.prototype.suggestSymbolFormat = function(symbol) {
    const formats = [
        { name: 'Standard', example: symbol },
        { name: 'NSE Equity', example: `${symbol}-EQ` },
        { name: 'Yahoo NSE', example: `${symbol}.NS` },
        { name: 'Yahoo BSE', example: `${symbol}.BO` }
    ]
    
    return formats
}

IndianMarketUtils.prototype.convertSymbolFormat = function(symbol, targetFormat) {
    const cleanSymbol = symbol.toUpperCase().replace(/[^A-Z0-9]/g, '')
    
    switch (targetFormat) {
        case 'standard':
            return cleanSymbol
        case 'nse_equity':
            return `${cleanSymbol}-EQ`
        case 'yahoo_nse':
            return `${cleanSymbol}.NS`
        case 'yahoo_bse':
            return `${cleanSymbol}.BO`
        case 'upstox_nse':
            return `NSE_EQ|${this.getISINForSymbol(cleanSymbol)}`
        case 'upstox_bse':
            return `BSE_EQ|${this.getISINForSymbol(cleanSymbol)}`
        default:
            return cleanSymbol
    }
}

IndianMarketUtils.prototype.getISINForSymbol = function(symbol) {
    // This is a placeholder - in practice, you'd have a database of ISINs
    // For demonstration, we'll return a placeholder ISIN
    const isinMap = {
        'RELIANCE': 'INE002A01018',
        'TCS': 'INE467B01029',
        'INFY': 'INE009A01021',
        'HDFCBANK': 'INE040A01034',
        'ICICIBANK': 'INE090A01021',
        'SBIN': 'INE062A01020',
        'BHARTIARTL': 'INE397D01024',
        'KOTAKBANK': 'INE237A01028',
        'LT': 'INE018A01030',
        'ITC': 'INE154A01025'
    }
    
    return isinMap[symbol] || 'INE000000000'
}

IndianMarketUtils.prototype.getExchangeForSymbol = function(symbol) {
    // Simple heuristic for exchange detection
    const cleanSymbol = symbol.toUpperCase()
    
    // Check for explicit exchange indicators
    if (cleanSymbol.includes('BSE') || cleanSymbol.includes('.BO')) {
        return 'BSE'
    }
    
    if (cleanSymbol.includes('NSE') || cleanSymbol.includes('.NS') || cleanSymbol.includes('-EQ')) {
        return 'NSE'
    }
    
    // Default to NSE for Indian stocks
    return 'NSE'
}

IndianMarketUtils.prototype.getCurrencyForExchange = function(exchange) {
    switch (exchange.toUpperCase()) {
        case 'NSE':
        case 'BSE':
            return 'INR'
        default:
            return 'USD'
    }
}

IndianMarketUtils.prototype.formatINRAmount = function(amount) {
    if (amount === null || amount === undefined || isNaN(amount)) {
        return '₹0.00'
    }
    
    const formatter = new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    })
    
    return formatter.format(amount)
}

IndianMarketUtils.prototype.parseINRAmount = function(amountString) {
    if (!amountString) return 0
    
    // Remove currency symbols and commas
    const cleaned = amountString.replace(/[₹,]/g, '').trim()
    const parsed = parseFloat(cleaned)
    
    return isNaN(parsed) ? 0 : parsed
}

IndianMarketUtils.prototype.calculateDayChange = function(currentPrice, previousClose) {
    if (!currentPrice || !previousClose || previousClose === 0) {
        return { absolute: 0, percentage: 0 }
    }
    
    const absolute = currentPrice - previousClose
    const percentage = (absolute / previousClose) * 100
    
    return {
        absolute: Math.round(absolute * 100) / 100, // Round to 2 decimal places
        percentage: Math.round(percentage * 100) / 100 // Round to 2 decimal places
    }
}

IndianMarketUtils.prototype.getPopularIndianStocks = function() {
    return [
        { symbol: 'RELIANCE', name: 'Reliance Industries', sector: 'Oil & Gas' },
        { symbol: 'TCS', name: 'Tata Consultancy Services', sector: 'IT' },
        { symbol: 'INFY', name: 'Infosys Limited', sector: 'IT' },
        { symbol: 'HDFCBANK', name: 'HDFC Bank Limited', sector: 'Banking' },
        { symbol: 'ICICIBANK', name: 'ICICI Bank Limited', sector: 'Banking' },
        { symbol: 'SBIN', name: 'State Bank of India', sector: 'Banking' },
        { symbol: 'BHARTIARTL', name: 'Bharti Airtel Limited', sector: 'Telecom' },
        { symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank', sector: 'Banking' },
        { symbol: 'LT', name: 'Larsen & Toubro Limited', sector: 'Construction' },
        { symbol: 'ITC', name: 'ITC Limited', sector: 'FMCG' },
        { symbol: 'HINDUNILVR', name: 'Hindustan Unilever Limited', sector: 'FMCG' },
        { symbol: 'WIPRO', name: 'Wipro Limited', sector: 'IT' },
        { symbol: 'MARUTI', name: 'Maruti Suzuki India Limited', sector: 'Automobile' },
        { symbol: 'TATAMOTORS', name: 'Tata Motors Limited', sector: 'Automobile' },
        { symbol: 'ONGC', name: 'Oil and Natural Gas Corporation', sector: 'Oil & Gas' }
    ]
}