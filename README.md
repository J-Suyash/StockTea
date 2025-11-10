# [WIP] StockTea - Enhanced Stock Portfolio Widget for KDE Plasma - Indian Equities Edition

A KDE Plasma 6 applet that displays real-time Indian stock portfolio data using the Upstox v3 REST API, with a clean interface inspired by weather widgets.

## Features

### ✅ Implemented Features

- **Upstox v3 API Integration**: Real-time stock data from India's leading trading platform
- **Indian Stock Support**: Full support for NSE/BSE equities with symbol search
- **ISIN Resolution**: Automatic mapping from human-readable symbols (e.g., RELIANCE) to ISINs
- **Portfolio Management**: Add, edit, and remove positions with buying price tracking
- **Real-time P/L**: Live profit/loss calculations with percentage changes
- **Candlestick Charts**: Interactive charts with multiple timeframes (1m, 5m, 15m, 30m, 1h, 1d, 1w, 1M)
- **Market Hours**: Respects Indian market hours (9:15 AM - 3:30 PM IST, Mon-Fri)
- **Data Persistence**: Portfolio positions saved across sessions
- **Responsive UI**: Adaptive design that works in both compact and expanded modes

### 🚧 Planned Features

- Price alerts and notifications
- Multiple watchlists
- Enhanced analytics (sector allocation, diversification scores)
- Sound notifications

## Installation

### Prerequisites
- KDE Plasma 6.0+
- Internet connection
- Optional: Upstox API credentials (only needed for authenticated endpoints)

### Installation Steps

1. **Copy the widget directory:**
   ```bash
   mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.widgets.stocktea
   cp -r contents/ metadata.json ~/.local/share/plasma/plasmoids/org.kde.plasma.widgets.stocktea/
   ```

2. **Restart Plasma:**
   ```bash
   kquitapp5 plasmashell && kstart5 plasmashell
   ```

3. **Add to Panel:**
   - Right-click panel → "Add Widgets..."
   - Search for "StockTea"
   - Drag to desired location

## Usage

### Adding Stocks to Portfolio

1. **Open Widget Settings:**
   - Right-click widget → "Configure StockTea"

2. **Go to Manage Tab:**
   - Click "Add Position"
   - Enter symbol (e.g., "RELIANCE", "TCS", "INFY")
   - Search will show available Indian stocks
   - Set quantity and buying price
   - Click "Add Position"

### Viewing Charts

1. **Click on any position** in the portfolio view
2. **Switch to Chart tab** in the expanded view
3. **Select timeframe** from dropdown (1m to 1M)
4. **View candlestick data** with OHLC values

### Managing Positions

1. **Edit Position:**
   - Click "Edit" button on any position
   - Update quantity or buying price
   - Click "Update Position"

2. **Remove Position:**
   - Click "Remove" button on any position
   - Confirm removal

## Indian Stock Symbol Formats

The widget supports multiple Indian stock symbol formats:

- **Standard**: `RELIANCE`, `TCS`, `INFY`
- **Yahoo Finance**: `RELIANCE.NS`, `TCS.NS`
- **Exchange Format**: `RELIANCE-EQ`, `TCS-EQ`

Popular Indian stocks that work out of the box:
- RELIANCE (Reliance Industries)
- TCS (Tata Consultancy Services)
- INFY (Infosys Limited)
- HDFCBANK (HDFC Bank)
- ICICIBANK (ICICI Bank)
- SBIN (State Bank of India)

## API Integration

### Upstox v3 REST API

The widget uses Upstox's public endpoints for market data:

- **Quote Data**: `/v2/quote/{symbol}` - Real-time prices
- **Historical Data**: `/v2/historical-candle/{symbol}/{interval}/{from}/{to}` - Candlestick data

### Data Sources

1. **Primary**: Upstox v3 API (Indian stocks)
2. **Fallback**: Yahoo Finance for broader symbol support

## Configuration

### Widget Settings

- **Refresh Interval**: How often to fetch new data (1-60 minutes)
- **Market Hours**: Enable/disable Indian market hours restriction
- **Currency**: Set to INR for Indian markets
- **Debug Logging**: Enable for troubleshooting

### Portfolio Settings

- **Name**: Give your portfolio a custom name
- **Currency**: Automatically set to INR
- **Positions**: Add/edit/remove stock positions

## Architecture

### File Structure

```
stocktea/
├── metadata.json              # Widget metadata
├── contents/
│   ├── code/
│   │   ├── upstox-data-loader.js    # Upstox API integration
│   │   ├── stock-data-loader.js     # Legacy compatibility
│   │   ├── portfolio-model.js       # Portfolio calculations
│   │   └── stock_processor.py       # Python backend (optional)
│   └── ui/
│       ├── main.qml                 # Main widget logic
│       ├── FullRepresentation.qml   # Expanded view
│       ├── CompactRepresentation.qml # Compact view
│       ├── PortfolioView.qml        # Portfolio display
│       ├── ChartView.qml           # Chart visualization
│       ├── PositionItem.qml        # Individual position item
│       └── ManageView.qml          # Position management
```

### Key Components

- **main.qml**: Main widget controller and data flow
- **upstox-data-loader.js**: Upstox API integration and data parsing
- **PortfolioView.qml**: Portfolio positions display
- **ChartView.qml**: Candlestick chart visualization
- **ManageView.qml**: Add/edit positions interface

## Development

### Testing

Run the comprehensive test to validate the widget:
```bash
python test_comprehensive.py
```

This will check for:
- QML syntax errors
- UI sizing issues
- Icon improvements
- Code quality

### Contributing

1. Follow KDE Plasma coding standards
2. Test with Indian market data
3. Ensure proper error handling
4. Update documentation

## Troubleshooting

### No Data Displaying
- Check internet connection
- Verify symbol format (use standard Indian symbols)
- Enable debug logging in settings
- Check network logs in the widget

### Chart Not Loading
- Verify symbol has sufficient historical data
- Try different timeframe (1d instead of 1m)
- Check if market is open (data limited outside market hours)

### Widget Sizing Issues
- Test with `python test_comprehensive.py`
- Check responsive layout constraints
- Verify Plasma theme compatibility

## License

This project is open source. Please check individual licenses for third-party dependencies.

## Support

For issues and feature requests, please report them through the appropriate channels.

---

**Built specifically for Indian equities with comprehensive Upstox API integration and intelligent fallback systems for reliable market data access.**
