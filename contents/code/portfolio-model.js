/*
 * Portfolio data model and management utilities
 * Adapted from weather widget architecture for financial data
 */

function createEmptyStockPosition() {
    return {
        id: '',
        symbol: '',
        name: '',
        quantity: 0,
        buyingPrice: 0.0,
        currentPrice: 0.0,
        currency: 'USD',
        lastUpdate: new Date(),
        dayChange: 0.0,
        dayChangePercent: 0.0,
        totalValue: 0.0,
        totalCost: 0.0,
        profitLoss: 0.0,
        profitLossPercent: 0.0
    }
}

function createEmptyPortfolio() {
    return {
        id: '',
        name: '',
        positions: [],
        totalValue: 0.0,
        totalCost: 0.0,
        totalProfitLoss: 0.0,
        totalProfitLossPercent: 0.0,
        dayChange: 0.0,
        dayChangePercent: 0.0,
        lastUpdate: new Date(),
        currency: 'USD'
    }
}

function createEmptyCandlestickData() {
    return {
        timestamp: new Date(),
        open: 0.0,
        high: 0.0,
        low: 0.0,
        close: 0.0,
        volume: 0
    }
}

function calculatePositionMetrics(position) {
    position.totalCost = position.quantity * position.buyingPrice
    position.totalValue = position.quantity * position.currentPrice
    position.profitLoss = position.totalValue - position.totalCost
    position.profitLossPercent = position.totalCost > 0 ? (position.profitLoss / position.totalCost) * 100 : 0
    return position
}

function calculatePortfolioMetrics(portfolio) {
    portfolio.totalCost = 0
    portfolio.totalValue = 0
    portfolio.dayChange = 0
    
    for (let i = 0; i < portfolio.positions.length; i++) {
        let position = portfolio.positions[i]
        portfolio.totalCost += position.totalCost
        portfolio.totalValue += position.totalValue
        portfolio.dayChange += (position.dayChangePercent * position.totalValue) / 100
    }
    
    portfolio.totalProfitLoss = portfolio.totalValue - portfolio.totalCost
    portfolio.totalProfitLossPercent = portfolio.totalCost > 0 ? (portfolio.totalProfitLoss / portfolio.totalCost) * 100 : 0
    portfolio.dayChangePercent = portfolio.totalValue > 0 ? (portfolio.dayChange / portfolio.totalValue) * 100 : 0
    
    return portfolio
}

function formatCurrency(amount, currency = 'USD') {
    const symbols = {
        'USD': '$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'CNY': '¥'
    }
    
    const symbol = symbols[currency] || currency + ' '
    return symbol + Math.abs(amount).toFixed(2)
}

function formatPercent(percent) {
    return (percent >= 0 ? '+' : '') + percent.toFixed(2) + '%'
}

function generatePositionId(symbol) {
    return 'pos_' + symbol.toLowerCase().replace(/[^a-z0-9]/g, '_')
}

function validatePosition(position) {
    const errors = []
    
    if (!position.symbol || position.symbol.trim() === '') {
        errors.push('Symbol is required')
    }
    
    if (position.quantity <= 0) {
        errors.push('Quantity must be greater than 0')
    }
    
    if (position.buyingPrice <= 0) {
        errors.push('Buying price must be greater than 0')
    }
    
    return errors
}

function getPortfolioFromConfig() {
    try {
        const configData = plasmoid.configuration.portfolios
        return JSON.parse(configData || '[]')
    } catch (error) {
        dbgprint('Error parsing portfolio configuration: ' + error.message)
        return []
    }
}

function savePortfolioToConfig(portfolios) {
    try {
        plasmoid.configuration.portfolios = JSON.stringify(portfolios)
        return true
    } catch (error) {
        dbgprint('Error saving portfolio configuration: ' + error.message)
        return false
    }
}

function generateCacheKey(symbol, timeframe) {
    return 'stock_' + Qt.md5(symbol + '_' + timeframe)
}

function isMarketOpen() {
    const now = new Date()
    const day = now.getDay()
    const hour = now.getHours()
    
    // Simple market hours check (9:30 AM - 4:00 PM EST, Mon-Fri)
    // This is a simplified version - real implementation would need timezone handling
    return day >= 1 && day <= 5 && hour >= 9 && hour < 16
}

function getLastUpdateTimeText(lastUpdate) {
    if (!lastUpdate) return i18n("Never")
    
    const now = new Date().getTime()
    const updateTime = new Date(lastUpdate).getTime()
    const diffMs = now - updateTime
    const diffMins = Math.floor(diffMs / 60000)
    
    if (diffMins < 1) return i18n("Just now")
    if (diffMins < 60) return i18n("%1 min ago", diffMins)
    
    const diffHours = Math.floor(diffMins / 60)
    if (diffHours < 24) return i18n("%1 hrs ago", diffHours)
    
    const diffDays = Math.floor(diffHours / 24)
    return i18n("%1 days ago", diffDays)
}