#!/usr/bin/env python3
"""
StockTea - Python Backend
Processes stock data and provides enhanced analytics
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class StockProcessor:
    """Main stock data processing class"""

    def __init__(self):
        self.session = None
        self.cache = {}
        self.cache_ttl = 300  # 5 minutes cache

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
        Get real-time stock quote

        Args:
            symbol: Stock symbol (e.g., 'AAPL', 'GOOGL')
            provider: Data provider ('yahoo')

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
            else:
                raise ValueError(f"Unsupported provider: {provider}")

            # Cache the result
            self._cache_data(cache_key, quote_data)
            
            return quote_data
            
        except Exception as e:
            logger.error(f"Error getting quote for {symbol}: {e}")
            return self._get_error_response(symbol, str(e))
    
    async def get_candlestick_data(self, symbol: str, timeframe: str = "1d",
                                provider: str = "yahoo") -> List[Dict[str, Any]]:
        """
        Get candlestick chart data

        Args:
            symbol: Stock symbol
            timeframe: Time interval ('1m', '5m', '15m', '30m', '1h', '1d', '1w', '1M')
            provider: Data provider ('yahoo')

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
            else:
                raise ValueError(f"Unsupported provider: {provider}")

            # Cache the result
            self._cache_data(cache_key, chart_data)
            
            return chart_data
            
        except Exception as e:
            logger.error(f"Error getting chart data for {symbol}: {e}")
            return []
    
    
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
        Calculate portfolio metrics

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
            
            enhanced_position = position.copy()
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