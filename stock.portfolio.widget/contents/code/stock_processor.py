#!/usr/bin/env python3
"""
StockTea - Python Backend with Context7 Integration
Processes stock data and provides enhanced analytics

Copyright 2024 StockTea
This program is free software; you can redistribute it and/or modify
it under terms of the GNU General Public License as published by
Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
"""

import sys
import json
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import aiohttp
import pandas as pd
import numpy as np

# Context7 integration for enhanced stock data processing
try:
    from context7 import Context7Client
    CONTEXT7_AVAILABLE = True
except ImportError:
    CONTEXT7_AVAILABLE = False
    print("Warning: Context7 not available, using fallback processing")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class StockProcessor:
    """Main stock data processing class with Context7 integration"""
    
    def __init__(self):
        self.context7_client = None
        self.session = None
        self.cache = {}
        self.cache_ttl = 300  # 5 minutes cache
        
        # Initialize Context7 if available
        if CONTEXT7_AVAILABLE:
            try:
                self.context7_client = Context7Client()
                logger.info("Context7 client initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Context7: {e}")
        
        # Initialize HTTP session
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=30),
            headers={'User-Agent': 'StockPortfolioWidget/1.0'}
        )
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.close()
    
    def _get_cache_key(self, symbol: str, data_type: str) -> str:
        """Generate cache key for stock data"""
        return f"{symbol}_{data_type}_{datetime.now().strftime('%Y%m%d_%H%M')}"
    
    def _is_cache_valid(self, cache_key: str) -> bool:
        """Check if cached data is still valid"""
        if cache_key not in self.cache:
            return False
        
        cached_time = self.cache[cache_key].get('timestamp', 0)
        return (datetime.now().timestamp() - cached_time) < self.cache_ttl
    
    def _cache_data(self, cache_key: str, data: Any):
        """Cache stock data with timestamp"""
        self.cache[cache_key] = {
            'data': data,
            'timestamp': datetime.now().timestamp()
        }
    
    async def get_stock_quote(self, symbol: str, provider: str = "yahoo") -> Dict[str, Any]:
        """
        Get real-time stock quote with Context7 enhancement
        
        Args:
            symbol: Stock symbol (e.g., 'AAPL', 'GOOGL')
            provider: Data provider ('yahoo', 'alphavantage', 'polygon')
            
        Returns:
            Dictionary containing stock quote data
        """
        cache_key = self._get_cache_key(symbol, "quote")
        
        # Check cache first
        if self._is_cache_valid(cache_key):
            logger.info(f"Returning cached quote for {symbol}")
            return self.cache[cache_key]['data']
        
        try:
            if provider == "yahoo":
                quote_data = await self._get_yahoo_quote(symbol)
            elif provider == "alphavantage":
                quote_data = await self._get_alphavantage_quote(symbol)
            elif provider == "polygon":
                quote_data = await self._get_polygon_quote(symbol)
            else:
                raise ValueError(f"Unsupported provider: {provider}")
            
            # Enhance with Context7 if available
            if self.context7_client and CONTEXT7_AVAILABLE:
                quote_data = await self._enhance_with_context7(quote_data, symbol)
            
            # Cache the result
            self._cache_data(cache_key, quote_data)
            
            return quote_data
            
        except Exception as e:
            logger.error(f"Error getting quote for {symbol}: {e}")
            return self._get_error_response(symbol, str(e))
    
    async def get_candlestick_data(self, symbol: str, timeframe: str = "1d", 
                                provider: str = "yahoo") -> List[Dict[str, Any]]:
        """
        Get candlestick chart data with Context7 enhancement
        
        Args:
            symbol: Stock symbol
            timeframe: Time interval ('1m', '5m', '15m', '30m', '1h', '1d', '1w', '1M')
            provider: Data provider
            
        Returns:
            List of candlestick data points
        """
        cache_key = self._get_cache_key(symbol, f"candlestick_{timeframe}")
        
        # Check cache first
        if self._is_cache_valid(cache_key):
            logger.info(f"Returning cached candlestick data for {symbol}")
            return self.cache[cache_key]['data']
        
        try:
            if provider == "yahoo":
                chart_data = await self._get_yahoo_chart(symbol, timeframe)
            elif provider == "alphavantage":
                chart_data = await self._get_alphavantage_chart(symbol, timeframe)
            elif provider == "polygon":
                chart_data = await self._get_polygon_chart(symbol, timeframe)
            else:
                raise ValueError(f"Unsupported provider: {provider}")
            
            # Enhance with Context7 if available
            if self.context7_client and CONTEXT7_AVAILABLE:
                chart_data = await self._enhance_chart_with_context7(chart_data, symbol)
            
            # Cache the result
            self._cache_data(cache_key, chart_data)
            
            return chart_data
            
        except Exception as e:
            logger.error(f"Error getting chart data for {symbol}: {e}")
            return []
    
    async def _enhance_with_context7(self, quote_data: Dict[str, Any], symbol: str) -> Dict[str, Any]:
        """Enhance stock quote with Context7 analytics"""
        try:
            # Get additional context from Context7
            context_data = await self.context7_client.get_stock_context(symbol)
            
            # Add Context7 insights to quote data
            quote_data['context7_sentiment'] = context_data.get('sentiment', 0)
            quote_data['context7_news_count'] = context_data.get('news_count', 0)
            quote_data['context7_analyst_rating'] = context_data.get('analyst_rating', 'HOLD')
            quote_data['context7_volatility'] = context_data.get('volatility_score', 0.5)
            quote_data['context7_trend'] = context_data.get('trend', 'NEUTRAL')
            
            logger.info(f"Enhanced {symbol} with Context7 data")
            return quote_data
            
        except Exception as e:
            logger.warning(f"Failed to enhance {symbol} with Context7: {e}")
            return quote_data
    
    async def _enhance_chart_with_context7(self, chart_data: List[Dict[str, Any]], 
                                        symbol: str) -> List[Dict[str, Any]]:
        """Enhance chart data with Context7 technical indicators"""
        try:
            # Convert to pandas for analysis
            df = pd.DataFrame(chart_data)
            
            # Get Context7 technical analysis
            ta_data = await self.context7_client.get_technical_analysis(symbol, df)
            
            # Add technical indicators to each candlestick
            for i, candle in enumerate(chart_data):
                if i < len(ta_data.get('sma_20', [])):
                    candle['sma_20'] = ta_data['sma_20'][i]
                if i < len(ta_data.get('rsi', [])):
                    candle['rsi'] = ta_data['rsi'][i]
                if i < len(ta_data.get('macd', [])):
                    candle['macd'] = ta_data['macd'][i]
            
            logger.info(f"Enhanced {symbol} chart with Context7 technical indicators")
            return chart_data
            
        except Exception as e:
            logger.warning(f"Failed to enhance {symbol} chart with Context7: {e}")
            return chart_data
    
    async def _get_yahoo_quote(self, symbol: str) -> Dict[str, Any]:
        """Get quote from Yahoo Finance API"""
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                data = await response.json()
                return self._parse_yahoo_quote(data, symbol)
            else:
                raise Exception(f"Yahoo API error: {response.status}")
    
    async def _get_yahoo_chart(self, symbol: str, timeframe: str) -> List[Dict[str, Any]]:
        """Get chart data from Yahoo Finance API"""
        interval_map = {
            '1m': '1m', '5m': '5m', '15m': '15m', '30m': '30m',
            '1h': '1h', '1d': '1d', '1w': '1wk', '1M': '1mo'
        }
        
        interval = interval_map.get(timeframe, '1d')
        range_map = {'1d': '1d', '1w': '5d', '1M': '1mo'}
        range_param = range_map.get(timeframe, '1d')
        
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval={interval}&range={range_param}"
        
        async with self.session.get(url) as response:
            if response.status == 200:
                data = await response.json()
                return self._parse_yahoo_chart(data)
            else:
                raise Exception(f"Yahoo chart API error: {response.status}")
    
    def _parse_yahoo_quote(self, data: Dict[str, Any], symbol: str) -> Dict[str, Any]:
        """Parse Yahoo Finance quote response"""
        try:
            chart = data.get('chart', {}).get('result', [])
            if not chart:
                return self._get_error_response(symbol, "No data available")
            
            result = chart[0]
            meta = result.get('meta', {})
            timestamps = result.get('timestamp', [])
            quotes = result.get('indicators', {}).get('quote', [])
            
            if not timestamps or not quotes:
                return self._get_error_response(symbol, "No quote data")
            
            latest_idx = len(timestamps) - 1
            quote = quotes[0]
            
            current_price = quote.get('close', [0])[latest_idx] or 0
            open_price = quote.get('open', [0])[latest_idx] or 0
            high_price = quote.get('high', [0])[latest_idx] or 0
            low_price = quote.get('low', [0])[latest_idx] or 0
            volume = quote.get('volume', [0])[latest_idx] or 0
            
            # Calculate day change
            prev_close = meta.get('previousClose', current_price)
            day_change = current_price - prev_close
            day_change_percent = (day_change / prev_close * 100) if prev_close > 0 else 0
            
            return {
                'symbol': symbol,
                'currentPrice': current_price,
                'openPrice': open_price,
                'highPrice': high_price,
                'lowPrice': low_price,
                'volume': volume,
                'dayChange': day_change,
                'dayChangePercent': day_change_percent,
                'timestamp': datetime.fromtimestamp(timestamps[latest_idx]),
                'currency': meta.get('currency', 'USD'),
                'provider': 'yahoo'
            }
            
        except Exception as e:
            logger.error(f"Error parsing Yahoo quote: {e}")
            return self._get_error_response(symbol, f"Parse error: {e}")
    
    def _parse_yahoo_chart(self, data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Parse Yahoo Finance chart response"""
        try:
            chart = data.get('chart', {}).get('result', [])
            if not chart:
                return []
            
            result = chart[0]
            timestamps = result.get('timestamp', [])
            quotes = result.get('indicators', {}).get('quote', [])
            
            if not timestamps or not quotes:
                return []
            
            candlesticks = []
            quote = quotes[0]
            
            for i, timestamp in enumerate(timestamps):
                if i < len(quote.get('close', [])):
                    candlestick = {
                        'timestamp': datetime.fromtimestamp(timestamp),
                        'open': quote.get('open', [0])[i] or 0,
                        'high': quote.get('high', [0])[i] or 0,
                        'low': quote.get('low', [0])[i] or 0,
                        'close': quote.get('close', [0])[i] or 0,
                        'volume': quote.get('volume', [0])[i] or 0
                    }
                    candlesticks.append(candlestick)
            
            return candlesticks
            
        except Exception as e:
            logger.error(f"Error parsing Yahoo chart: {e}")
            return []
    
    async def _get_alphavantage_quote(self, symbol: str) -> Dict[str, Any]:
        """Get quote from Alpha Vantage API"""
        # Implementation would require API key
        return self._get_error_response(symbol, "Alpha Vantage not implemented")
    
    async def _get_alphavantage_chart(self, symbol: str, timeframe: str) -> List[Dict[str, Any]]:
        """Get chart data from Alpha Vantage API"""
        # Implementation would require API key
        return []
    
    async def _get_polygon_quote(self, symbol: str) -> Dict[str, Any]:
        """Get quote from Polygon.io API"""
        # Implementation would require API key
        return self._get_error_response(symbol, "Polygon.io not implemented")
    
    async def _get_polygon_chart(self, symbol: str, timeframe: str) -> List[Dict[str, Any]]:
        """Get chart data from Polygon.io API"""
        # Implementation would require API key
        return []
    
    def _get_error_response(self, symbol: str, error_msg: str) -> Dict[str, Any]:
        """Generate error response"""
        return {
            'symbol': symbol,
            'error': True,
            'errorMessage': error_msg,
            'currentPrice': 0,
            'dayChange': 0,
            'dayChangePercent': 0,
            'timestamp': datetime.now()
        }
    
    def calculate_portfolio_metrics(self, positions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Calculate portfolio metrics with Context7 enhancement
        
        Args:
            positions: List of position dictionaries
            
        Returns:
            Dictionary with portfolio metrics
        """
        if not positions:
            return {
                'totalValue': 0,
                'totalCost': 0,
                'totalProfitLoss': 0,
                'totalProfitLossPercent': 0,
                'dayChange': 0,
                'dayChangePercent': 0,
                'positions': []
            }
        
        total_value = 0
        total_cost = 0
        day_change = 0
        
        enhanced_positions = []
        
        for position in positions:
            quantity = position.get('quantity', 0)
            buying_price = position.get('buyingPrice', 0)
            current_price = position.get('currentPrice', 0)
            
            position_cost = quantity * buying_price
            position_value = quantity * current_price
            position_pl = position_value - position_cost
            position_pl_percent = (position_pl / position_cost * 100) if position_cost > 0 else 0
            
            total_cost += position_cost
            total_value += position_value
            day_change += position.get('dayChange', 0) * quantity
            
            # Enhance position with Context7 insights if available
            enhanced_position = position.copy()
            if self.context7_client and CONTEXT7_AVAILABLE:
                enhanced_position['context7_risk_score'] = self._calculate_risk_score(position)
                enhanced_position['context7_recommendation'] = self._get_recommendation(position)
            
            enhanced_position.update({
                'totalCost': position_cost,
                'totalValue': position_value,
                'profitLoss': position_pl,
                'profitLossPercent': position_pl_percent
            })
            
            enhanced_positions.append(enhanced_position)
        
        total_pl = total_value - total_cost
        total_pl_percent = (total_pl / total_cost * 100) if total_cost > 0 else 0
        day_change_percent = (day_change / total_value * 100) if total_value > 0 else 0
        
        return {
            'totalValue': total_value,
            'totalCost': total_cost,
            'totalProfitLoss': total_pl,
            'totalProfitLossPercent': total_pl_percent,
            'dayChange': day_change,
            'dayChangePercent': day_change_percent,
            'positions': enhanced_positions
        }
    
    def _calculate_risk_score(self, position: Dict[str, Any]) -> float:
        """Calculate risk score for a position"""
        # Simple risk calculation based on volatility and position size
        volatility = position.get('context7_volatility', 0.5)
        quantity = position.get('quantity', 0)
        
        # Risk score: 0 (low risk) to 1 (high risk)
        risk_score = min(1.0, volatility * (quantity / 100))
        return risk_score
    
    def _get_recommendation(self, position: Dict[str, Any]) -> str:
        """Get investment recommendation based on Context7 data"""
        sentiment = position.get('context7_sentiment', 0)
        trend = position.get('context7_trend', 'NEUTRAL')
        pl_percent = position.get('profitLossPercent', 0)
        
        # Simple recommendation logic
        if sentiment > 0.3 and trend in ['BULLISH', 'UP']:
            return 'BUY'
        elif sentiment < -0.3 and trend in ['BEARISH', 'DOWN']:
            return 'SELL'
        elif pl_percent > 20:
            return 'TAKE_PROFIT'
        elif pl_percent < -20:
            return 'STOP_LOSS'
        else:
            return 'HOLD'


async def main():
    """Main function for testing the processor"""
    processor = StockProcessor()
    
    try:
        # Test with a sample stock
        quote = await processor.get_stock_quote("AAPL")
        print(f"AAPL Quote: {json.dumps(quote, indent=2, default=str)}")
        
        # Test chart data
        chart_data = await processor.get_candlestick_data("AAPL", "1d")
        print(f"AAPL Chart points: {len(chart_data)}")
        
        # Test portfolio metrics
        positions = [
            {
                'symbol': 'AAPL',
                'quantity': 10,
                'buyingPrice': 150.0,
                'currentPrice': 170.0,
                'dayChange': 2.5,
                'dayChangePercent': 1.5
            }
        ]
        
        metrics = processor.calculate_portfolio_metrics(positions)
        print(f"Portfolio metrics: {json.dumps(metrics, indent=2, default=str)}")
        
    except Exception as e:
        logger.error(f"Error in main: {e}")
    finally:
        await processor.__aexit__(None, None, None)


if __name__ == "__main__":
    # Run the processor
    asyncio.run(main())