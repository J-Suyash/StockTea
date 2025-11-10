#!/bin/bash

# StockTea - KDE Plasma Widget Installation Script
# Installs the StockTea stock portfolio widget

set -e

# Configuration
WIDGET_NAME="org.kde.plasma.widgets.stocktea"
WIDGET_DIR="$HOME/.local/share/plasma/plasmoids/$WIDGET_NAME"
PLASMOIDS_DIR="$HOME/.local/share/plasma/plasmoids"

echo "🚀 StockTea - KDE Plasma Widget Installer"
echo "=========================================="

# Check if running on Linux with KDE Plasma
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ Error: This installation script is for Linux only"
    exit 1
fi

# Check if KDE Plasma is available
if ! command -v plasmashell &> /dev/null; then
    echo "❌ Error: KDE Plasma not found. Please install KDE Plasma first."
    exit 1
fi

echo "✅ KDE Plasma detected"

# Create plasmoids directory if it doesn't exist
mkdir -p "$PLASMOIDS_DIR"

# Check if widget directory exists
if [ -d "$WIDGET_DIR" ]; then
    echo "⚠️  Warning: Widget directory already exists"
    echo "   This will overwrite the existing installation."
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    
    # Backup existing installation
    BACKUP_DIR="$WIDGET_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📦 Creating backup: $BACKUP_DIR"
    mv "$WIDGET_DIR" "$BACKUP_DIR"
fi

# Create new widget directory
echo "📁 Creating widget directory..."
mkdir -p "$WIDGET_DIR"

# Copy widget files
echo "📋 Copying widget files..."
if [ -d "contents" ]; then
    cp -r contents/ "$WIDGET_DIR/"
    echo "   ✅ contents/ copied"
else
    echo "   ❌ Error: contents/ directory not found"
    echo "   Please run this script from the widget source directory"
    exit 1
fi

if [ -f "metadata.json" ]; then
    cp metadata.json "$WIDGET_DIR/"
    echo "   ✅ metadata.json copied"
else
    echo "   ❌ Error: metadata.json not found"
    exit 1
fi

# Validate installation
echo ""
echo "🔍 Validating installation..."

# Check required files
REQUIRED_FILES=(
    "metadata.json"
    "contents/ui/main.qml"
    "contents/code/upstox-data-loader.js"
    "contents/code/portfolio-model.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$WIDGET_DIR/$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ Missing: $file"
        echo "Installation failed - required files missing"
        exit 1
    fi
done

# Test QML syntax (basic check)
echo ""
echo "🧪 Testing QML syntax..."
if command -v qml &> /dev/null; then
    # Basic syntax check
    if qml -syntax "$WIDGET_DIR/contents/ui/main.qml" &> /dev/null; then
        echo "   ✅ main.qml syntax OK"
    else
        echo "   ⚠️  Warning: main.qml syntax check failed"
    fi
else
    echo "   ⚠️  Warning: qml command not found, skipping syntax check"
fi

# Set up environment variables for QML
echo "⚙️  Setting up QML environment..."
ENV_FILE="$HOME/.config/plasma-stocktea-env.sh"
cat > "$ENV_FILE" << 'EOF'
#!/bin/bash
# Environment variables for StockTea widget
export QML_XHR_ALLOW_FILE_READ=1
EOF

# Add to shell profile if not already there
if [ -f "$HOME/.bashrc" ] && ! grep -q "QML_XHR_ALLOW_FILE_READ" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# StockTea widget environment" >> "$HOME/.bashrc"
    echo "export QML_XHR_ALLOW_FILE_READ=1" >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ] && ! grep -q "QML_XHR_ALLOW_FILE_READ" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# StockTea widget environment" >> "$HOME/.zshrc"
    echo "export QML_XHR_ALLOW_FILE_READ=1" >> "$HOME/.zshrc"
fi

# Set environment for current session
export QML_XHR_ALLOW_FILE_READ=1
echo "   ✅ Environment configured"

# Set proper permissions
echo "🔐 Setting permissions..."
chmod -R 755 "$WIDGET_DIR"
echo "   ✅ Permissions set"

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. IMPORTANT: Log out and log back in to load environment variables"
echo "   2. Or restart Plasma shell:"
echo "      kquitapp5 plasmashell && kstart5 plasmashell"
echo ""
echo "   3. Add widget to panel:"
echo "      - Right-click panel → Add Widgets..."
echo "      - Search for 'StockTea'"
echo "      - Drag to desired location"
echo ""
echo "📁 Installation location: $WIDGET_DIR"
echo ""
echo "📖 For usage instructions, see README.md"
echo ""
echo "🔧 Configuration:"
echo "   Right-click widget → Configure to set up your portfolio"
echo ""
echo "⚠️  Important: Environment variables have been set for QML file access."
echo "   Please log out/in to ensure they are properly loaded."
echo ""

# Optional: Restart Plasma now
echo ""
read -p "Restart Plasma shell now? (recommended) (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "🔄 Restarting Plasma shell..."
    if pgrep -x plasmashell > /dev/null; then
        kquitapp5 plasmashell
        sleep 2
        kstart5 plasmashell
        echo "✅ Plasma shell restarted"
    else
        echo "⚠️  Plasma shell not running, please restart manually"
    fi
fi

echo ""
echo "🎯 StockTea is ready to use!"