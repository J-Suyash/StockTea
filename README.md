# [WIP] StockTea - Enhanced Stock Portfolio Widget for KDE Plasma - Indian Equities Edition

## Overview

This enhanced KDE Plasma widget provides comprehensive real-time monitoring of Indian stock market portfolios with advanced features including Upstox API integration, fallback data sources, Indian market hours handling, watchlists, price alerts, and sophisticated portfolio analytics.

## Key Features

### 🎯 Primary Data Source
- **Upstox API Integration** - Official Indian trading platform API
  - Real-time market quotes (`/v2/quote/{symbol}`)
  - Historical candlestick data (`/v2/historical-candle/{symbol}/{interval}/{from_date}/{to_date}`)
  - Portfolio positions (`/v2/portfolio/long-term-positions`)
  - Full market quotes (`/market-quote/quotes/full`)

### 🔄 Fallback Data Sources
- **Yahoo Finance** - Free Indian stock data (e.g., RELIANCE.NS)
- **NSE/BSE Direct** - Official exchange data feeds
- **MarketStack** - Basic market data with API key
- **Alpha Vantage** - Financial data with premium features

### 🇮🇳 Indian Market Features
- **Market Hours**: 9:15 AM to 3:30 PM IST (Monday-Friday)
- **Holiday Support**: Configurable Indian market holidays
- **Timezone Handling**: Automatic IST conversion
- **Currency**: INR formatting with Indian number system (lakhs/crores)
- **Symbol Validation**: NSE/BSE symbol format support
- **Popular Stocks**: Pre-configured Indian stock symbols

### 📊 Portfolio Analytics
- **Enhanced P&L Tracking**: Real-time profit/loss calculations
- **Sector Allocation**: Visual pie charts and breakdown
- **Diversification Score**: Portfolio risk assessment (0-100)
- **Top Performers**: Track best/worst performing positions
- **Win Rate**: Percentage of winning positions
- **Risk Metrics**: Concentration analysis

### ⚡ Real-Time Monitoring
- **Configurable Refresh**: 15-60 second intervals
- **Offline Mode**: Cached data when internet unavailable
- **Error Recovery**: Automatic fallback on API failures
- **Market Status**: Live market open/closed indicator

### 🔔 Watchlists & Alerts
- **Multiple Watchlists**: Organize stocks by categories
- **Price Alerts**: Above/below/percent change triggers
- **Sound Notifications**: Optional audio alerts
- **Visual Indicators**: Color-coded alerts
- **Alert History**: Track triggered alerts

### 📈 Advanced Charts
- **Multiple Timeframes**: 1m, 5m, 15m, 30m, 1h, 1d, 1w, 1M
- **Candlestick Charts**: OHLC data visualization
- **Volume Display**: Optional volume bars
- **Technical Indicators**: Basic price action analysis

### 🎨 User Interface
- **Responsive Design**: Adapts to panel sizes
- **Compact Mode**: Space-efficient layout
- **KDE Integration**: Native Plasma theming
- **Color Coding**: Price changes with visual indicators
- **Dashboard View**: Comprehensive portfolio overview

## Installation

### Prerequisites
- KDE Plasma 5.27+
- Qt 5.15+
- Internet connection for live data
- Optional: Upstox API credentials for full features

### Installation Steps

1. **Copy Widget Files**
   ```bash
   cp -r stocktea ~/.local/share/plasma/plasmoids/
   ```

2. **Install Dependencies** (Optional)
   ```bash
   # For enhanced data processing
   pip install aiohttp pandas numpy

   # For Upstox API (if using)
   # Get credentials from: https://upstox.com/developer/api/
   ```

3. **Restart Plasma**
   ```bash
   kquitapp5 plasmashell && kstart5 plasmashell
   ```

4. **Add to Panel**
   - Right-click panel → "Add Widgets..."
   - Search "StockTea"
   - Drag to desired location

## Configuration

### API Setup

#### Upstox API (Recommended)
1. Get API credentials from [Upstox Developer Portal](https://upstox.com/developer/api/)
2. Right-click widget → "Configure"
3. Go to "API" tab
4. Select "Upstox (Primary)"
5. Enter API Key and Access Token
6. Enable "Enable Fallback" for redundancy

#### Free Alternatives
- **Yahoo Finance**: No setup required (limited reliability)
- **NSE/BSE**: Automatic symbol validation

### Indian Market Settings
1. Go to "IndianMarkets" configuration tab
2. Set exchange mode (NSE/BSE/Both)
3. Configure market hours (default: 9:15-15:30 IST)
4. Add custom holidays
5. Choose symbol format preference

### Alert Configuration
1. Go to "Alerts" tab
2. Enable price/portfolio alerts
3. Set alert threshold percentages
4. Configure notification preferences
5. Enable/disable sound alerts

### Watchlist Setup
1. Go to "Watchlist" tab
2. Add custom watchlists
3. Populate with Indian stock symbols
4. Set refresh intervals
5. Configure alert triggers

## Usage

### Adding Indian Stock Positions

1. **Right-click widget** → "Configure"
2. **Go to "Manage" tab**
3. **Add Position**:
   - Symbol: `RELIANCE` (Standard), `RELIANCE-EQ` (Exchange), or `NSE_EQ|INE002A01018` (Upstox format)
   - Quantity: Number of shares
   - Buying Price: Price per share in INR
   - Currency: Automatically set to INR

### Setting Up Alerts

1. **Configure Alerts Tab**
2. **Add Price Alert**:
   - Symbol: `TCS`
   - Condition: Above/Below/Change %
   - Target Value: ₹4500 (or 5% for change alerts)
   - Enable sound/notification

### Creating Watchlists

1. **Configure Watchlists Tab**
2. **Add Watchlist**: "IT Stocks"
3. **Add Symbols**: `TCS`, `INFY`, `WIPRO`, `HCLTECH`
4. **Set refresh interval**: 30 seconds

### Viewing Charts

1. **Click on any position** in the portfolio view
2. **Switch to "Chart" tab**
3. **Select timeframe**: 1m, 5m, 15m, 1h, 1d, 1w, 1M
4. **View candlestick data** with volume

## Indian Stock Symbols

### Supported Formats
- **Standard**: `RELIANCE`, `TCS`, `INFY`
- **Exchange Format**: `RELIANCE-EQ`, `TCS-EQ`
- **Yahoo Finance**: `RELIANCE.NS`, `TCS.NS`
- **Upstox Format**: `NSE_EQ|INE002A01018`, `BSE_EQ|INE467B01029`

### Popular Indian Stocks
```javascript
[
  "RELIANCE", // Reliance Industries
  "TCS",      // Tata Consultancy Services
  "INFY",     // Infosys Limited
  "HDFCBANK", // HDFC Bank
  "ICICIBANK",// ICICI Bank
  "SBIN",     // State Bank of India
  "BHARTIARTL", // Bharti Airtel
  "KOTAKBANK", // Kotak Mahindra Bank
  "LT",       // Larsen & Toubro
  "ITC"       // ITC Limited
]
```

## API Endpoints Reference

### Upstox API Integration

#### Market Quotes
```javascript
GET /v2/quote/{symbol}
Headers: {
  'Api-Key': 'YOUR_API_KEY',
  'Authorization': 'Bearer YOUR_ACCESS_TOKEN'
}
```

#### Historical Candles
```javascript
GET /v2/historical-candle/{symbol}/{interval}/{from_date}/{to_date}
// Example: /v2/historical-candle/RELIANCE-EQ/1day/2024-01-01/2024-12-31
```

#### Portfolio Positions
```javascript
GET /v2/portfolio/long-term-positions
```

### Fallback Sources

#### Yahoo Finance
```javascript
https://query1.finance.yahoo.com/v8/finance/chart/RELIANCE.NS?interval=1d&range=1mo
```

#### NSE/BSE Direct
```javascript
https://www.bseindia.com/stockinfo/stockinfoeq_NSE_RELIANCE.json
```

## Troubleshooting

### Common Issues

#### No Data Displaying
- Check internet connection
- Verify API credentials
- Enable debug logging in settings
- Check symbol format (use standard Indian format)

#### Market Hours Issues
- Widget respects Indian market hours (9:15-15:30 IST)
- Disable "Indian Market Hours" in config to update outside market hours
- Check holiday calendar in settings

#### API Rate Limits
- Increase refresh interval
- Enable fallback sources
- Use Yahoo Finance for unlimited free requests

#### Symbol Validation Errors
- Use supported symbol formats
- Check NSE/BSE symbol database
- Enable "Both NSE & BSE" in exchange settings

### Debug Mode
1. Enable "Debug Logging" in General settings
2. Check system logs:
   ```bash
   journalctl -f | grep -i stock
   ```
3. Monitor network requests in browser developer tools

## Development

### Project Structure
```
stocktea/
├── contents/
│   ├── code/
│   │   ├── upstox-data-loader.js      # Upstox API integration
│   │   ├── fallback-data-loader.js    # Alternative data sources
│   │   ├── indian-market-utils.js     # Indian market utilities
│   │   ├── watchlist-manager.js       # Alert and watchlist system
│   │   ├── portfolio-model-enhanced.js # Enhanced portfolio calculations
│   │   ├── stock-data-loader.js       # Main data loader
│   │   └── portfolio-model.js         # Legacy compatibility
│   ├── ui/
│   │   ├── EnhancedDashboard.qml      # Main dashboard
│   │   ├── FullRepresentation.qml     # Extended view
│   │   ├── CompactRepresentation.qml  # Compact view
│   │   ├── PortfolioView.qml          # Portfolio list
│   │   ├── ChartView.qml              # Chart visualization
│   │   └── ManageView.qml             # Position management
│   └── config/
│       ├── main.xml                   # Enhanced configuration
│       ├── ConfigAPI.qml              # API settings
│       ├── ConfigGeneral.qml          # General settings
│       └── config.qml                 # Configuration categories
├── metadata.desktop                   # Plasma widget metadata
└── README.md                         # This file
```

### Key Components

#### Data Flow
1. `main.qml` orchestrates data loading
2. `stock-data-loader.js` manages API calls
3. `upstox-data-loader.js` handles Upstox integration
4. `fallback-data-loader.js` provides alternatives
5. `indian-market-utils.js` manages market-specific logic

#### UI Architecture
- **EnhancedDashboard**: Main portfolio view
- **CompactRepresentation**: Panel/tray display
- **Tabbed Interface**: Portfolio/Chart/Manage views
- **Responsive Design**: Adapts to different screen sizes

### Extending the Widget

#### Adding New Data Sources
1. Create new loader in `fallback-data-loader.js`
2. Add to priority list in constructor
3. Implement parsing methods
4. Update configuration options

#### Custom Indicators
1. Extend `portfolio-model-enhanced.js`
2. Add calculation methods
3. Update UI components
4. Add configuration options

#### New Chart Types
1. Extend `ChartView.qml`
2. Add chart type selection
3. Implement rendering logic
4. Add data transformation

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/enhancement`
3. Follow KDE coding standards
4. Test with Indian market data
5. Submit pull request with detailed description

## Support

- **Issues**: Report bugs on GitHub Issues
- **Documentation**: Check configuration examples
- **Community**: KDE Plasma community forums
- **API Support**: Upstox Developer Portal

---

**Built specifically for Indian equities with comprehensive Upstox API integration and intelligent fallback systems for reliable market data access.**
