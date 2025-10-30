/*
 * Watchlist and Alert System for Indian Equities
 * Provides real-time monitoring and notification capabilities
 */

function WatchlistManager() {
    this.watchlists = this.loadWatchlists()
    this.alerts = this.loadAlerts()
    this.priceHistory = {} // Store price history for trend analysis
    this.alertSounds = plasmoid.configuration.alertSounds || false
    this.alertNotifications = plasmoid.configuration.alertNotifications || true
}

WatchlistManager.prototype.loadWatchlists = function() {
    try {
        const watchlistsData = plasmoid.configuration.watchlists || '[]'
        return JSON.parse(watchlistsData)
    } catch (error) {
        dbgprint('Error loading watchlists: ' + error.message)
        return []
    }
}

WatchlistManager.prototype.saveWatchlists = function() {
    try {
        plasmoid.configuration.watchlists = JSON.stringify(this.watchlists)
        return true
    } catch (error) {
        dbgprint('Error saving watchlists: ' + error.message)
        return false
    }
}

WatchlistManager.prototype.loadAlerts = function() {
    try {
        const alertsData = plasmoid.configuration.priceAlerts || '[]'
        return JSON.parse(alertsData)
    } catch (error) {
        dbgprint('Error loading alerts: ' + error.message)
        return []
    }
}

WatchlistManager.prototype.saveAlerts = function() {
    try {
        plasmoid.configuration.priceAlerts = JSON.stringify(this.alerts)
        return true
    } catch (error) {
        dbgprint('Error saving alerts: ' + error.message)
        return false
    }
}

WatchlistManager.prototype.addWatchlist = function(name, symbols) {
    const watchlist = {
        id: this.generateId(),
        name: name,
        symbols: symbols || [],
        created: new Date().toISOString(),
        lastUpdated: new Date().toISOString()
    }
    
    this.watchlists.push(watchlist)
    this.saveWatchlists()
    return watchlist
}

WatchlistManager.prototype.removeWatchlist = function(id) {
    const index = this.watchlists.findIndex(w => w.id === id)
    if (index >= 0) {
        this.watchlists.splice(index, 1)
        this.saveWatchlists()
        return true
    }
    return false
}

WatchlistManager.prototype.updateWatchlist = function(id, updates) {
    const watchlist = this.watchlists.find(w => w.id === id)
    if (watchlist) {
        Object.assign(watchlist, updates)
        watchlist.lastUpdated = new Date().toISOString()
        this.saveWatchlists()
        return watchlist
    }
    return null
}

WatchlistManager.prototype.addSymbolToWatchlist = function(watchlistId, symbol) {
    const watchlist = this.watchlists.find(w => w.id === watchlistId)
    if (watchlist && !watchlist.symbols.includes(symbol)) {
        watchlist.symbols.push(symbol)
        watchlist.lastUpdated = new Date().toISOString()
        this.saveWatchlists()
        return true
    }
    return false
}

WatchlistManager.prototype.removeSymbolFromWatchlist = function(watchlistId, symbol) {
    const watchlist = this.watchlists.find(w => w.id === watchlistId)
    if (watchlist) {
        const index = watchlist.symbols.indexOf(symbol)
        if (index >= 0) {
            watchlist.symbols.splice(index, 1)
            watchlist.lastUpdated = new Date().toISOString()
            this.saveWatchlists()
            return true
        }
    }
    return false
}

WatchlistManager.prototype.addPriceAlert = function(alert) {
    const newAlert = {
        id: this.generateId(),
        symbol: alert.symbol.toUpperCase(),
        condition: alert.condition, // 'above', 'below', 'change_percent'
        targetValue: parseFloat(alert.targetValue),
        currentValue: 0,
        triggered: false,
        triggeredAt: null,
        enabled: true,
        created: new Date().toISOString(),
        sound: alert.sound || false,
        message: alert.message || ''
    }
    
    this.alerts.push(newAlert)
    this.saveAlerts()
    return newAlert
}

WatchlistManager.prototype.removeAlert = function(id) {
    const index = this.alerts.findIndex(a => a.id === id)
    if (index >= 0) {
        this.alerts.splice(index, 1)
        this.saveAlerts()
        return true
    }
    return false
}

WatchlistManager.prototype.toggleAlert = function(id, enabled) {
    const alert = this.alerts.find(a => a.id === id)
    if (alert) {
        alert.enabled = enabled
        this.saveAlerts()
        return alert
    }
    return null
}

WatchlistManager.prototype.checkAlerts = function(symbol, currentPrice, previousPrice, dayChangePercent) {
    const matchingAlerts = this.alerts.filter(alert => 
        alert.symbol === symbol.toUpperCase() && 
        alert.enabled && 
        !alert.triggered
    )
    
    matchingAlerts.forEach(alert => {
        let shouldTrigger = false
        
        switch (alert.condition) {
            case 'above':
                shouldTrigger = currentPrice >= alert.targetValue
                break
            case 'below':
                shouldTrigger = currentPrice <= alert.targetValue
                break
            case 'change_percent':
                shouldTrigger = Math.abs(dayChangePercent) >= alert.targetValue
                break
        }
        
        if (shouldTrigger) {
            this.triggerAlert(alert, currentPrice, previousPrice, dayChangePercent)
        }
    })
}

WatchlistManager.prototype.triggerAlert = function(alert, currentPrice, previousPrice, dayChangePercent) {
    alert.triggered = true
    alert.triggeredAt = new Date().toISOString()
    alert.currentValue = currentPrice
    
    this.saveAlerts()
    
    // Show notification
    if (this.alertNotifications) {
        this.showAlertNotification(alert, currentPrice, dayChangePercent)
    }
    
    // Play sound
    if (alert.sound || this.alertSounds) {
        this.playAlertSound()
    }
    
    // Send system notification
    this.sendSystemNotification(alert, currentPrice, dayChangePercent)
}

WatchlistManager.prototype.showAlertNotification = function(alert, currentPrice, dayChangePercent) {
    const conditionText = {
        'above': 'reached ₹' + alert.targetValue,
        'below': 'fell below ₹' + alert.targetValue,
        'change_percent': 'changed by ' + alert.targetValue + '%'
    }
    
    const message = `Alert for ${alert.symbol}: Price ${conditionText[alert.condition]} (Current: ₹${currentPrice})`
    
    // Show KDE notification (this would integrate with Plasma notifications)
    if (typeof showPassiveNotification === 'function') {
        showPassiveNotification(message, 5000)
    } else {
        dbgprint('ALERT: ' + message)
    }
}

WatchlistManager.prototype.playAlertSound = function() {
    // This would play a system sound for alerts
    // Implementation would depend on system capabilities
    dbgprint('Playing alert sound for: ' + alert.symbol)
}

WatchlistManager.prototype.sendSystemNotification = function(alert, currentPrice, dayChangePercent) {
    // Send system notification using Plasma API
    const notification = {
        summary: `Stock Alert: ${alert.symbol}`,
        body: `Price ${alert.condition} ${alert.targetValue}. Current: ₹${currentPrice}`,
        icon: 'stock-info',
        category: 'stock-alert'
    }
    
    // This would use Plasma notification API
    dbgprint('System notification sent: ' + JSON.stringify(notification))
}

WatchlistManager.prototype.resetAlert = function(id) {
    const alert = this.alerts.find(a => a.id === id)
    if (alert) {
        alert.triggered = false
        alert.triggeredAt = null
        alert.currentValue = 0
        this.saveAlerts()
        return alert
    }
    return null
}

WatchlistManager.prototype.updatePriceHistory = function(symbol, price) {
    if (!this.priceHistory[symbol]) {
        this.priceHistory[symbol] = []
    }
    
    this.priceHistory[symbol].push({
        timestamp: new Date(),
        price: price
    })
    
    // Keep only last 100 price points
    if (this.priceHistory[symbol].length > 100) {
        this.priceHistory[symbol] = this.priceHistory[symbol].slice(-100)
    }
}

WatchlistManager.prototype.getPriceHistory = function(symbol, timeframe = '1d') {
    const history = this.priceHistory[symbol] || []
    const now = new Date()
    let startTime
    
    switch (timeframe) {
        case '1h':
            startTime = new Date(now.getTime() - (60 * 60 * 1000))
            break
        case '1d':
            startTime = new Date(now.getTime() - (24 * 60 * 60 * 1000))
            break
        case '1w':
            startTime = new Date(now.getTime() - (7 * 24 * 60 * 60 * 1000))
            break
        default:
            startTime = new Date(0)
    }
    
    return history.filter(entry => entry.timestamp >= startTime)
}

WatchlistManager.prototype.getTrendingSymbols = function() {
    const trends = []
    
    Object.keys(this.priceHistory).forEach(symbol => {
        const history = this.getPriceHistory(symbol, '1d')
        if (history.length >= 2) {
            const firstPrice = history[0].price
            const lastPrice = history[history.length - 1].price
            const change = ((lastPrice - firstPrice) / firstPrice) * 100
            
            trends.push({
                symbol: symbol,
                change: change,
                firstPrice: firstPrice,
                lastPrice: lastPrice,
                trend: change > 0 ? 'up' : 'down'
            })
        }
    })
    
    return trends.sort((a, b) => Math.abs(b.change) - Math.abs(a.change))
}

WatchlistManager.prototype.getWatchlistWithPrices = function(watchlistId) {
    const watchlist = this.watchlists.find(w => w.id === watchlistId)
    if (!watchlist) return null
    
    return {
        ...watchlist,
        prices: this.getPriceHistoryForSymbols(watchlist.symbols)
    }
}

WatchlistManager.prototype.getPriceHistoryForSymbols = function(symbols) {
    const prices = {}
    
    symbols.forEach(symbol => {
        const history = this.getPriceHistory(symbol, '1d')
        if (history.length > 0) {
            const latest = history[history.length - 1]
            prices[symbol] = {
                current: latest.price,
                change: history.length > 1 ? latest.price - history[0].price : 0,
                changePercent: history.length > 1 ? ((latest.price - history[0].price) / history[0].price) * 100 : 0,
                history: history
            }
        }
    })
    
    return prices
}

WatchlistManager.prototype.generateId = function() {
    return 'id_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now()
}

WatchlistManager.prototype.exportWatchlists = function() {
    return {
        version: '2.0',
        exportDate: new Date().toISOString(),
        watchlists: this.watchlists,
        alerts: this.alerts
    }
}

WatchlistManager.prototype.importWatchlists = function(importData) {
    try {
        if (importData.watchlists && Array.isArray(importData.watchlists)) {
            this.watchlists = importData.watchlists
            this.saveWatchlists()
        }
        
        if (importData.alerts && Array.isArray(importData.alerts)) {
            this.alerts = importData.alerts
            this.saveAlerts()
        }
        
        return true
    } catch (error) {
        dbgprint('Error importing watchlists: ' + error.message)
        return false
    }
}

WatchlistManager.prototype.getAlertStatistics = function() {
    const total = this.alerts.length
    const triggered = this.alerts.filter(a => a.triggered).length
    const enabled = this.alerts.filter(a => a.enabled && !a.triggered).length
    
    return {
        total: total,
        triggered: triggered,
        enabled: enabled,
        disabled: total - enabled
    }
}

WatchlistManager.prototype.cleanupOldAlerts = function(daysToKeep = 30) {
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep)
    
    this.alerts = this.alerts.filter(alert => {
        const alertDate = new Date(alert.created)
        return alertDate >= cutoffDate || alert.enabled
    })
    
    this.saveAlerts()
}