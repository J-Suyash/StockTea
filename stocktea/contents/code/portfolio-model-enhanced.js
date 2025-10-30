/*
 * Enhanced Portfolio Model for Indian Equities
 * Updated with Indian market features and comprehensive calculations
 */

function createEmptyIndianStockPosition() {
    return {
        id: '',
        symbol: '',
        name: '',
        quantity: 0,
        buyingPrice: 0.0,
        currentPrice: 0.0,
        currency: 'INR',
        exchange: 'NSE',
        lastUpdate: new Date(),
        dayChange: 0.0,
        dayChangePercent: 0.0,
        totalValue: 0.0,
        totalCost: 0.0,
        profitLoss: 0.0,
        profitLossPercent: 0.0,
        volume: 0,
        marketCap: null,
        peRatio: null,
        high52Week: 0.0,
        low52Week: 0.0,
        avgVolume: 0,
        sector: '',
        companyName: ''
    }
}

function createEmptyIndianPortfolio() {
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
        currency: 'INR',
        exchange: 'NSE',
        totalPositions: 0,
        winningPositions: 0,
        losingPositions: 0,
        topGainer: null,
        topLoser: null,
        sectorAllocation: {},
        diversification: 0
    }
}

function calculateEnhancedPositionMetrics(position) {
    // Basic calculations
    position.totalCost = position.quantity * position.buyingPrice
    position.totalValue = position.quantity * position.currentPrice
    position.profitLoss = position.totalValue - position.totalCost
    position.profitLossPercent = position.totalCost > 0 ? (position.profitLoss / position.totalCost) * 100 : 0
    
    // Enhanced metrics for Indian stocks
    if (position.high52Week > 0 && position.low52Week > 0) {
        const currentYearHigh = (position.currentPrice / position.high52Week) * 100
        const currentYearLow = (position.currentPrice / position.low52Week) * 100
        position.yearHighPercent = currentYearHigh
        position.yearLowPercent = currentYearLow
    }
    
    // Market cap based calculations (if available)
    if (position.marketCap && position.marketCap > 0) {
        position.positionWeight = (position.totalValue / position.marketCap) * 100
    }
    
    return position
}

function calculateEnhancedPortfolioMetrics(portfolio) {
    portfolio.totalCost = 0
    portfolio.totalValue = 0
    portfolio.dayChange = 0
    portfolio.totalPositions = portfolio.positions.length
    portfolio.winningPositions = 0
    portfolio.losingPositions = 0
    portfolio.sectorAllocation = {}
    portfolio.topGainer = null
    portfolio.topLoser = null
    portfolio.maxGain = 0
    portfolio.maxLoss = 0
    
    for (let i = 0; i < portfolio.positions.length; i++) {
        let position = portfolio.positions[i]
        portfolio.totalCost += position.totalCost
        portfolio.totalValue += position.totalValue
        portfolio.dayChange += (position.dayChangePercent * position.totalValue) / 100
        
        // Track winning/losing positions
        if (position.profitLoss > 0) {
            portfolio.winningPositions++
        } else if (position.profitLoss < 0) {
            portfolio.losingPositions++
        }
        
        // Track top gainer and loser
        if (position.profitLossPercent > portfolio.maxGain) {
            portfolio.maxGain = position.profitLossPercent
            portfolio.topGainer = position
        }
        
        if (position.profitLossPercent < portfolio.maxLoss) {
            portfolio.maxLoss = position.profitLossPercent
            portfolio.topLoser = position
        }
        
        // Sector allocation
        const sector = position.sector || 'Unknown'
        if (!portfolio.sectorAllocation[sector]) {
            portfolio.sectorAllocation[sector] = {
                value: 0,
                weight: 0,
                positions: 0
            }
        }
        portfolio.sectorAllocation[sector].value += position.totalValue
        portfolio.sectorAllocation[sector].positions++
    }
    
    portfolio.totalProfitLoss = portfolio.totalValue - portfolio.totalCost
    portfolio.totalProfitLossPercent = portfolio.totalCost > 0 ? (portfolio.totalProfitLoss / portfolio.totalCost) * 100 : 0
    portfolio.dayChangePercent = portfolio.totalValue > 0 ? (portfolio.dayChange / portfolio.totalValue) * 100 : 0
    
    // Calculate sector weights
    Object.keys(portfolio.sectorAllocation).forEach(sector => {
        portfolio.sectorAllocation[sector].weight = (portfolio.sectorAllocation[sector].value / portfolio.totalValue) * 100
    })
    
    // Calculate diversification score
    portfolio.diversification = calculateDiversificationScore(portfolio.sectorAllocation)
    
    return portfolio
}

function calculateDiversificationScore(sectorAllocation) {
    const sectors = Object.keys(sectorAllocation)
    if (sectors.length <= 1) return 0
    
    // Calculate Herfindahl-Hirschman Index for diversification
    let hhi = 0
    sectors.forEach(sector => {
        const weight = sectorAllocation[sector].weight / 100
        hhi += weight * weight
    })
    
    // Convert to diversification score (0-100, higher is more diversified)
    return Math.round((1 - hhi) * 100)
}

function formatINRCurrency(amount, currency = 'INR') {
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

function formatINRNumber(amount) {
    if (amount === null || amount === undefined || isNaN(amount)) {
        return '0'
    }
    
    const formatter = new Intl.NumberFormat('en-IN')
    return formatter.format(amount)
}

function formatINRShort(amount) {
    if (amount === null || amount === undefined || isNaN(amount)) {
        return '₹0'
    }
    
    if (amount >= 10000000) { // 1 crore
        return '₹' + (amount / 10000000).toFixed(2) + 'Cr'
    } else if (amount >= 100000) { // 1 lakh
        return '₹' + (amount / 100000).toFixed(2) + 'L'
    } else if (amount >= 1000) { // 1 thousand
        return '₹' + (amount / 1000).toFixed(2) + 'K'
    } else {
        return '₹' + amount.toFixed(2)
    }
}

function formatPercent(percent) {
    if (percent === null || percent === undefined || isNaN(percent)) {
        return '0.00%'
    }
    const sign = percent >= 0 ? '+' : ''
    return sign + percent.toFixed(2) + '%'
}

function formatVolume(volume) {
    if (volume === null || volume === undefined || isNaN(volume)) {
        return '0'
    }
    
    if (volume >= 10000000) { // 1 crore
        return (volume / 10000000).toFixed(2) + 'Cr'
    } else if (volume >= 100000) { // 1 lakh
        return (volume / 100000).toFixed(2) + 'L'
    } else if (volume >= 1000) { // 1 thousand
        return (volume / 1000).toFixed(2) + 'K'
    } else {
        return volume.toString()
    }
}

function getChangeColor(change) {
    if (change > 0) return '#22c55e' // Green for positive
    if (change < 0) return '#ef4444' // Red for negative
    return '#6b7280' // Gray for neutral
}

function getChangeIcon(change) {
    if (change > 0) return '▲'
    if (change < 0) return '▼'
    return '●'
}

function validateIndianPosition(position) {
    const errors = []
    
    if (!position.symbol || position.symbol.trim() === '') {
        errors.push('Symbol is required')
    } else {
        // Additional validation for Indian symbols
        const symbolRegex = /^[A-Z]{2,10}$|^[A-Z]{2,10}-EQ$|^NSE_EQ\|[A-Z0-9]+$|^BSE_EQ\|[A-Z0-9]+$/
        if (!symbolRegex.test(position.symbol.toUpperCase())) {
            errors.push('Invalid Indian stock symbol format')
        }
    }
    
    if (position.quantity <= 0) {
        errors.push('Quantity must be greater than 0')
    }
    
    if (position.buyingPrice <= 0) {
        errors.push('Buying price must be greater than 0')
    }
    
    if (position.currency !== 'INR') {
        errors.push('Only INR currency is supported for Indian stocks')
    }
    
    return errors
}

function getPopularIndianStocks() {
    return [
        { symbol: 'RELIANCE', name: 'Reliance Industries', sector: 'Oil & Gas', marketCap: 'Large Cap' },
        { symbol: 'TCS', name: 'Tata Consultancy Services', sector: 'IT', marketCap: 'Large Cap' },
        { symbol: 'INFY', name: 'Infosys Limited', sector: 'IT', marketCap: 'Large Cap' },
        { symbol: 'HDFCBANK', name: 'HDFC Bank Limited', sector: 'Banking', marketCap: 'Large Cap' },
        { symbol: 'ICICIBANK', name: 'ICICI Bank Limited', sector: 'Banking', marketCap: 'Large Cap' },
        { symbol: 'SBIN', name: 'State Bank of India', sector: 'Banking', marketCap: 'Large Cap' },
        { symbol: 'BHARTIARTL', name: 'Bharti Airtel Limited', sector: 'Telecom', marketCap: 'Large Cap' },
        { symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank', sector: 'Banking', marketCap: 'Large Cap' },
        { symbol: 'LT', name: 'Larsen & Toubro Limited', sector: 'Construction', marketCap: 'Large Cap' },
        { symbol: 'ITC', name: 'ITC Limited', sector: 'FMCG', marketCap: 'Large Cap' },
        { symbol: 'HINDUNILVR', name: 'Hindustan Unilever Limited', sector: 'FMCG', marketCap: 'Large Cap' },
        { symbol: 'WIPRO', name: 'Wipro Limited', sector: 'IT', marketCap: 'Large Cap' },
        { symbol: 'MARUTI', name: 'Maruti Suzuki India Limited', sector: 'Automobile', marketCap: 'Large Cap' },
        { symbol: 'TATAMOTORS', name: 'Tata Motors Limited', sector: 'Automobile', marketCap: 'Large Cap' },
        { symbol: 'ONGC', name: 'Oil and Natural Gas Corporation', sector: 'Oil & Gas', marketCap: 'Large Cap' },
        { symbol: 'BAJFINANCE', name: 'Bajaj Finance Limited', sector: 'NBFC', marketCap: 'Large Cap' },
        { symbol: 'ASIANPAINT', name: 'Asian Paints Limited', sector: 'Paints', marketCap: 'Large Cap' },
        { symbol: 'AXISBANK', name: 'Axis Bank Limited', sector: 'Banking', marketCap: 'Large Cap' },
        { symbol: 'HCLTECH', name: 'HCL Technologies Limited', sector: 'IT', marketCap: 'Large Cap' },
        { symbol: 'TITAN', name: 'Titan Company Limited', sector: 'Jewellery', marketCap: 'Large Cap' }
    ]
}

function getSectorColors() {
    return {
        'Banking': '#3b82f6',
        'IT': '#10b981',
        'FMCG': '#f59e0b',
        'Automobile': '#ef4444',
        'Oil & Gas': '#8b5cf6',
        'Pharmaceuticals': '#06b6d4',
        'Steel': '#6b7280',
        'Telecom': '#ec4899',
        'Construction': '#f97316',
        'Cement': '#84cc16',
        'NBFC': '#6366f1',
        'Real Estate': '#14b8a6',
        'Power': '#f43f5e',
        'Chemicals': '#8b5cf6',
        'Textiles': '#eab308',
        'Aviation': '#06b6d4',
        'Retail': '#f59e0b',
        'Media': '#ef4444',
        'Others': '#6b7280'
    }
}

function getMarketCapCategory(marketCap) {
    if (!marketCap) return 'Unknown'
    
    if (marketCap >= 200000) return 'Large Cap'
    if (marketCap >= 5000) return 'Mid Cap'
    return 'Small Cap'
}

function calculatePortfolioBeta(portfolio, marketReturns) {
    // Simplified beta calculation
    // In practice, you'd need historical data for covariance calculation
    let portfolioReturns = []
    
    // This would require historical portfolio returns
    // For now, return a placeholder
    return 1.0
}

function getPortfolioRiskMetrics(portfolio) {
    const riskMetrics = {
        diversificationScore: portfolio.diversification,
        sectorConcentration: getMaxSectorWeight(portfolio.sectorAllocation),
        singlePositionWeight: getMaxPositionWeight(portfolio.positions),
        volatilityScore: 0, // Would need historical data
        riskLevel: 'Medium'
    }
    
    // Determine risk level based on metrics
    if (riskMetrics.diversificationScore < 30 || riskMetrics.sectorConcentration > 50) {
        riskMetrics.riskLevel = 'High'
    } else if (riskMetrics.diversificationScore > 70 && riskMetrics.sectorConcentration < 30) {
        riskMetrics.riskLevel = 'Low'
    }
    
    return riskMetrics
}

function getMaxSectorWeight(sectorAllocation) {
    let maxWeight = 0
    Object.keys(sectorAllocation).forEach(sector => {
        if (sectorAllocation[sector].weight > maxWeight) {
            maxWeight = sectorAllocation[sector].weight
        }
    })
    return maxWeight
}

function getMaxPositionWeight(positions) {
    if (positions.length === 0) return 0
    
    let maxWeight = 0
    const totalValue = positions.reduce((sum, pos) => sum + pos.totalValue, 0)
    
    positions.forEach(position => {
        const weight = (position.totalValue / totalValue) * 100
        if (weight > maxWeight) {
            maxWeight = weight
        }
    })
    
    return maxWeight
}

// Legacy functions for compatibility
function createEmptyStockPosition() {
    return createEmptyIndianStockPosition()
}

function createEmptyPortfolio() {
    return createEmptyIndianPortfolio()
}

function calculatePositionMetrics(position) {
    return calculateEnhancedPositionMetrics(position)
}

function calculatePortfolioMetrics(portfolio) {
    return calculateEnhancedPortfolioMetrics(portfolio)
}

function formatCurrency(amount, currency = 'INR') {
    return formatINRCurrency(amount, currency)
}