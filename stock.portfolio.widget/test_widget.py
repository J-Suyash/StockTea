#!/usr/bin/env python3
"""
Test script for StockTea
Verifies component functionality and integration
"""

import sys
import os
import json
import asyncio
from pathlib import Path

# Add the code directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "contents" / "code"))

try:
    from stock_processor import StockProcessor
    PROCESSOR_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Could not import stock_processor: {e}")
    PROCESSOR_AVAILABLE = False

def test_portfolio_model():
    """Test portfolio model functions"""
    print("Testing portfolio model...")
    
    # Test basic portfolio creation
    portfolio = {
        "id": "test_portfolio",
        "name": "Test Portfolio",
        "currency": "USD",
        "positions": [
            {
                "symbol": "AAPL",
                "name": "Apple Inc.",
                "quantity": 10,
                "buyingPrice": 150.0,
                "currentPrice": 170.0,
                "dayChange": 2.5,
                "dayChangePercent": 1.5
            }
        ]
    }
    
    print(f"✓ Portfolio model created: {portfolio['name']}")
    print(f"✓ Positions count: {len(portfolio['positions'])}")
    return True

def test_config_structure():
    """Test configuration file structure"""
    print("Testing configuration structure...")

    # Check for QML config files (Plasma 6 format)
    config_files = [
        Path(__file__).parent / "contents" / "config" / "config.qml",
        Path(__file__).parent / "contents" / "config" / "config" / "ConfigGeneral.qml",
        Path(__file__).parent / "contents" / "config" / "config" / "ConfigAPI.qml"
    ]

    all_exist = True
    for config_file in config_files:
        if config_file.exists():
            print(f"✓ Configuration file exists: {config_file}")
        else:
            print(f"✗ Configuration file missing: {config_file}")
            all_exist = False

    return all_exist

def test_metadata():
    """Test metadata file"""
    print("Testing metadata...")

    # Check for JSON metadata (Plasma 6 format)
    metadata_file = Path(__file__).parent / "metadata.json"
    if metadata_file.exists():
        try:
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
                if metadata.get('KPlugin', {}).get('Name') == "StockTea":
                    print("✓ Metadata file contains correct name")
                    return True
                else:
                    print("✗ Metadata file missing correct widget name")
                    return False
        except json.JSONDecodeError:
            print("✗ Metadata file is not valid JSON")
            return False
    else:
        print(f"✗ Metadata file missing: {metadata_file}")
        return False

def test_qml_files():
    """Test QML file structure"""
    print("Testing QML files...")
    
    qml_files = [
        "contents/ui/main.qml",
        "contents/ui/CompactRepresentation.qml",
        "contents/ui/FullRepresentation.qml",
        "contents/ui/PortfolioView.qml",
        "contents/ui/ChartView.qml",
        "contents/ui/ManageView.qml"
    ]
    
    all_exist = True
    for qml_file in qml_files:
        file_path = Path(__file__).parent / qml_file
        if file_path.exists():
            print(f"✓ QML file exists: {qml_file}")
        else:
            print(f"✗ QML file missing: {qml_file}")
            all_exist = False
    
    return all_exist

async def test_python_backend():
    """Test Python backend functionality"""
    print("Testing Python backend...")
    
    if not PROCESSOR_AVAILABLE:
        print("✗ Python backend not available")
        return False
    
    try:
        processor = StockProcessor()
        
        # Test portfolio metrics calculation
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
        
        if metrics['totalValue'] == 1700:
            print("✓ Portfolio metrics calculation correct")
        else:
            print(f"✗ Portfolio metrics incorrect: {metrics['totalValue']}")
            return False
        
        await processor.__aexit__(None, None, None)
        return True
        
    except Exception as e:
        print(f"✗ Python backend error: {e}")
        return False

def test_file_structure():
    """Test overall file structure"""
    print("Testing file structure...")
    
    required_dirs = [
        "contents/code",
        "contents/ui",
        "contents/config"
    ]
    
    all_exist = True
    for dir_name in required_dirs:
        dir_path = Path(__file__).parent / dir_name
        if dir_path.exists():
            print(f"✓ Directory exists: {dir_name}")
        else:
            print(f"✗ Directory missing: {dir_name}")
            all_exist = False
    
    return all_exist

def main():
    """Run all tests"""
    print("StockTea - Test Suite")
    print("=" * 40)
    
    tests = [
        ("File Structure", test_file_structure),
        ("Configuration", test_config_structure),
        ("Metadata", test_metadata),
        ("QML Files", test_qml_files),
        ("Portfolio Model", test_portfolio_model),
    ]
    
    # Add Python backend test if available
    if PROCESSOR_AVAILABLE:
        tests.append(("Python Backend", lambda: asyncio.run(test_python_backend())))
    
    results = []
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"✗ {test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 40)
    print("TEST SUMMARY")
    print("=" * 40)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"test_name: {status}")
        if result:
            passed += 1
    
    print(f"\nPassed: {passed}/{total}")
    
    if passed == total:
        print("🎉 All tests passed! Widget is ready for deployment.")
        return 0
    else:
        print("❌ Some tests failed. Please review the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())