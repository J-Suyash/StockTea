/*
 * StockTea - Manage View
 * Portfolio management interface for adding/editing positions
 *
 */
import QtQuick 2.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import QtQuick.Controls
import "../code/portfolio-model.js" as PortfolioModel

ScrollView {
    id: scrollView
    anchors.fill: parent
    
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property var editingPosition: null
    property bool isEditing: editingPosition !== null

    ColumnLayout {
        id: mainColumn
        width: scrollView.width
        spacing: 15

        // Portfolio Settings
        Rectangle {
            id: portfolioSettingsCard
            Layout.fillWidth: true
            Layout.preferredHeight: portfolioSettingsColumn.height + 20
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ColumnLayout {
                id: portfolioSettingsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                PlasmaComponents.Label {
                    text: i18n("Portfolio Settings")
                    font.pixelSize: defaultFontPixelSize * 1.1
                    font.bold: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Name:")
                        font.pixelSize: defaultFontPixelSize
                    }
                    
                    PlasmaComponents.TextField {
                        id: portfolioNameField
                        Layout.fillWidth: true
                        text: main.currentPortfolio.name || ""
                        placeholderText: i18n("Enter portfolio name")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Currency:")
                        font.pixelSize: defaultFontPixelSize
                    }
                    
                    PlasmaComponents.ComboBox {
                        id: currencyCombo
                        Layout.fillWidth: true
                        model: ["USD", "EUR", "GBP", "JPY", "CNY"]
                        currentIndex: model.indexOf(main.currentPortfolio.currency || "USD")
                    }
                }

                PlasmaComponents.Button {
                    text: i18n("Save Portfolio Settings")
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        savePortfolioSettings()
                    }
                }
            }
        }

        // Add/Edit Position
        Rectangle {
            id: positionFormCard
            Layout.fillWidth: true
            Layout.preferredHeight: positionFormColumn.height + 20
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ColumnLayout {
                id: positionFormColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                PlasmaComponents.Label {
                    text: isEditing ? i18n("Edit Position") : i18n("Add Position")
                    font.pixelSize: defaultFontPixelSize * 1.1
                    font.bold: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Symbol:")
                        font.pixelSize: defaultFontPixelSize
                        Layout.preferredWidth: 80
                    }
                    
                    PlasmaComponents.TextField {
                        id: symbolField
                        Layout.fillWidth: true
                        text: isEditing ? editingPosition.symbol : ""
                        placeholderText: i18n("e.g., AAPL, GOOGL, MSFT")
                        upperCase: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Name:")
                        font.pixelSize: defaultFontPixelSize
                        Layout.preferredWidth: 80
                    }
                    
                    PlasmaComponents.TextField {
                        id: nameField
                        Layout.fillWidth: true
                        text: isEditing ? editingPosition.name : ""
                        placeholderText: i18n("Optional: Company name")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Quantity:")
                        font.pixelSize: defaultFontPixelSize
                        Layout.preferredWidth: 80
                    }
                    
                    PlasmaComponents.SpinBox {
                        id: quantitySpinBox
                        Layout.fillWidth: true
                        from: 1
                        to: 999999
                        value: isEditing ? editingPosition.quantity : 1
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Buy Price:")
                        font.pixelSize: defaultFontPixelSize
                        Layout.preferredWidth: 80
                    }
                    
                    PlasmaComponents.TextField {
                        id: buyPriceField
                        Layout.fillWidth: true
                        text: isEditing ? editingPosition.buyingPrice.toFixed(2) : ""
                        placeholderText: i18n("0.00")
                        validator: DoubleValidator {
                            bottom: 0.01
                            decimals: 2
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: i18n("Currency:")
                        font.pixelSize: defaultFontPixelSize
                        Layout.preferredWidth: 80
                    }
                    
                    PlasmaComponents.ComboBox {
                        id: positionCurrencyCombo
                        Layout.fillWidth: true
                        model: ["USD", "EUR", "GBP", "JPY", "CNY"]
                        currentIndex: model.indexOf(isEditing ? editingPosition.currency : main.currentPortfolio.currency)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    PlasmaComponents.Button {
                        text: isEditing ? i18n("Update Position") : i18n("Add Position")
                        Layout.fillWidth: true
                        onClicked: {
                            if (isEditing) {
                                updatePosition()
                            } else {
                                addPosition()
                            }
                        }
                    }
                    
                    PlasmaComponents.Button {
                        text: i18n("Cancel")
                        visible: isEditing
                        Layout.fillWidth: true
                        onClicked: {
                            cancelEditing()
                        }
                    }
                }
            }
        }

        // Positions List
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(positionsListView.contentHeight + 20, 300)
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                PlasmaComponents.Label {
                    text: i18n("Current Positions (%1)", main.positionsModel.count)
                    font.pixelSize: defaultFontPixelSize * 1.1
                    font.bold: true
                    Layout.fillWidth: true
                }

                ListView {
                    id: positionsListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 200)
                    model: main.positionsModel
                    spacing: 5

                    delegate: Rectangle {
                        width: positionsListView.width
                        height: positionRow.height + 10
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: positionRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 5
                            spacing: 10

                            PlasmaComponents.Label {
                                text: model.symbol || ""
                                font.pixelSize: defaultFontPixelSize
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            PlasmaComponents.Label {
                                text: model.quantity ? model.quantity.toString() : "0"
                                font.pixelSize: defaultFontPixelSize
                            }

                            PlasmaComponents.Label {
                                text: model.buyingPrice ? 
                                       PortfolioModel.formatCurrency(model.buyingPrice, model.currency) : "--"
                                font.pixelSize: defaultFontPixelSize
                            }

                            PlasmaComponents.Button {
                                text: i18n("Edit")
                                onClicked: {
                                    startEditing(model)
                                }
                            }

                            PlasmaComponents.Button {
                                text: i18n("Remove")
                                onClicked: {
                                    removePosition(model)
                                }
                            }
                        }
                    }

                    // Empty state
                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: i18n("No positions in this portfolio")
                        font.pixelSize: defaultFontPixelSize
                        color: Kirigami.Theme.disabledTextColor
                        visible: main.positionsModel.count === 0
                    }
                }
            }
        }

        // Add some bottom spacing
        Item {
            Layout.preferredHeight: 20
        }
    }

    function savePortfolioSettings() {
        var portfolios = PortfolioModel.getPortfolioFromConfig()
        var portfolioIndex = plasmoid.configuration.portfolioIndex
        
        if (portfolioIndex >= 0 && portfolioIndex < portfolios.length) {
            portfolios[portfolioIndex].name = portfolioNameField.text
            portfolios[portfolioIndex].currency = currencyCombo.currentText
            
            if (PortfolioModel.savePortfolioToConfig(portfolios)) {
                main.currentPortfolio.name = portfolioNameField.text
                main.currentPortfolio.currency = currencyCombo.currentText
                main.fullRepresentationAlias = portfolioNameField.text
            }
        }
    }

    function addPosition() {
        var errors = validatePositionForm()
        if (errors.length > 0) {
            showError(errors.join("\n"))
            return
        }

        var newPosition = PortfolioModel.createEmptyStockPosition()
        newPosition.id = PortfolioModel.generatePositionId(symbolField.text)
        newPosition.symbol = symbolField.text.toUpperCase()
        newPosition.name = nameField.text || symbolField.text.toUpperCase()
        newPosition.quantity = quantitySpinBox.value
        newPosition.buyingPrice = parseFloat(buyPriceField.text)
        newPosition.currency = positionCurrencyCombo.currentText

        PortfolioModel.calculatePositionMetrics(newPosition)

        var portfolios = PortfolioModel.getPortfolioFromConfig()
        var portfolioIndex = plasmoid.configuration.portfolioIndex
        
        if (portfolioIndex >= 0 && portfolioIndex < portfolios.length) {
            portfolios[portfolioIndex].positions.push(newPosition)
            
            if (PortfolioModel.savePortfolioToConfig(portfolios)) {
                main.currentPortfolio.positions.push(newPosition)
                PortfolioModel.calculatePortfolioMetrics(main.currentPortfolio)
                main.updatePositionsModel()
                clearPositionForm()
            }
        }
    }

    function updatePosition() {
        var errors = validatePositionForm()
        if (errors.length > 0) {
            showError(errors.join("\n"))
            return
        }

        var updatedPosition = PortfolioModel.createEmptyStockPosition()
        updatedPosition.id = editingPosition.id
        updatedPosition.symbol = symbolField.text.toUpperCase()
        updatedPosition.name = nameField.text || symbolField.text.toUpperCase()
        updatedPosition.quantity = quantitySpinBox.value
        updatedPosition.buyingPrice = parseFloat(buyPriceField.text)
        updatedPosition.currency = positionCurrencyCombo.currentText

        PortfolioModel.calculatePositionMetrics(updatedPosition)

        var portfolios = PortfolioModel.getPortfolioFromConfig()
        var portfolioIndex = plasmoid.configuration.portfolioIndex
        
        if (portfolioIndex >= 0 && portfolioIndex < portfolios.length) {
            var positions = portfolios[portfolioIndex].positions
            for (var i = 0; i < positions.length; i++) {
                if (positions[i].id === updatedPosition.id) {
                    positions[i] = updatedPosition
                    break
                }
            }
            
            if (PortfolioModel.savePortfolioToConfig(portfolios)) {
                for (i = 0; i < main.currentPortfolio.positions.length; i++) {
                    if (main.currentPortfolio.positions[i].id === updatedPosition.id) {
                        main.currentPortfolio.positions[i] = updatedPosition
                        break
                    }
                }
                
                PortfolioModel.calculatePortfolioMetrics(main.currentPortfolio)
                main.updatePositionsModel()
                cancelEditing()
            }
        }
    }

    function removePosition(position) {
        var portfolios = PortfolioModel.getPortfolioFromConfig()
        var portfolioIndex = plasmoid.configuration.portfolioIndex
        
        if (portfolioIndex >= 0 && portfolioIndex < portfolios.length) {
            var positions = portfolios[portfolioIndex].positions
            for (var i = 0; i < positions.length; i++) {
                if (positions[i].id === position.id) {
                    positions.splice(i, 1)
                    break
                }
            }
            
            if (PortfolioModel.savePortfolioToConfig(portfolios)) {
                for (i = 0; i < main.currentPortfolio.positions.length; i++) {
                    if (main.currentPortfolio.positions[i].id === position.id) {
                        main.currentPortfolio.positions.splice(i, 1)
                        break
                    }
                }
                
                PortfolioModel.calculatePortfolioMetrics(main.currentPortfolio)
                main.updatePositionsModel()
            }
        }
    }

    function startEditing(position) {
        editingPosition = position
        symbolField.text = position.symbol
        nameField.text = position.name
        quantitySpinBox.value = position.quantity
        buyPriceField.text = position.buyingPrice.toFixed(2)
        positionCurrencyCombo.currentIndex = positionCurrencyCombo.model.indexOf(position.currency)
    }

    function cancelEditing() {
        editingPosition = null
        clearPositionForm()
    }

    function clearPositionForm() {
        symbolField.text = ""
        nameField.text = ""
        quantitySpinBox.value = 1
        buyPriceField.text = ""
        positionCurrencyCombo.currentIndex = positionCurrencyCombo.model.indexOf(main.currentPortfolio.currency)
    }

    function validatePositionForm() {
        var errors = []
        
        if (!symbolField.text || symbolField.text.trim() === "") {
            errors.push(i18n("Symbol is required"))
        }
        
        if (quantitySpinBox.value <= 0) {
            errors.push(i18n("Quantity must be greater than 0"))
        }
        
        var buyPrice = parseFloat(buyPriceField.text)
        if (isNaN(buyPrice) || buyPrice <= 0) {
            errors.push(i18n("Buy price must be greater than 0"))
        }
        
        return errors
    }

    function showError(message) {
        // Simple error display - could be enhanced with a proper dialog
        console.error("Error: " + message)
    }

    Component.onCompleted: {
        clearPositionForm()
    }
}