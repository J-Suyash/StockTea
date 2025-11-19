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
import Qt.labs.platform 1.1
import "../code/portfolio-model.js" as PortfolioModel
import "../code/upstox-data-loader.js" as Upstox

ScrollView {
    id: scrollView
    
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property var editingPosition: null
    property bool isEditing: editingPosition !== null
    property var upstoxApi: new Upstox.UpstoxAPI()
    property var selectedInstrument: null
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 500

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
                        
                        Component.onCompleted: {
                            // Ensure field is populated on load
                            text = main.currentPortfolio.name || i18n("My Portfolio")
                        }
                        
                        Connections {
                            target: main
                            function onCurrentPortfolioChanged() {
                                portfolioNameField.text = main.currentPortfolio.name || i18n("My Portfolio")
                            }
                        }
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
                        placeholderText: i18n("e.g., RELIANCE, TCS, INFY")
                        inputMethodHints: Qt.ImhUppercaseOnly
                        onTextChanged: {
                            selectedInstrument = null
                            suggestionDebounce.restart()
                        }
                        onEditingFinished: suggestionsPopup.visible = false
                    }
                }

                ListModel { id: symbolSuggestions }

                Timer {
                    id: suggestionDebounce
                    interval: 250
                    repeat: false
                onTriggered: {
                    console.log("StockTea: Search debounce triggered")
                    var q = symbolField.text.trim()
                        if (q.length < 2) {
                            symbolSuggestions.clear();
                            suggestionsPopup.visible = false;
                            console.log("StockTea: Search query too short: " + q)
                            if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                main.dbgprint("Search query too short: " + q)
                            }
                            return
                        }
                        
                        console.log("StockTea: Starting search for: " + q)
                        if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                            main.dbgprint("Starting search for: " + q)
                        }
                        
                        // Ensure instruments are loaded (gz JSON -> parsed -> cached), fallback to API CSV path
                        var ensureLoaded = function(next) {
                            console.log("StockTea: Checking if instruments loaded, count: " + (upstoxApi._instruments ? upstoxApi._instruments.length : 0))
                            if (upstoxApi._instruments && upstoxApi._instruments.length) { next(); return }
                            console.log("StockTea: Fetching instruments...")
                            upstoxApi.fetchInstruments(function(){ 
                                console.log("StockTea: Instruments fetch success")
                                next() 
                            }, function(err){ 
                                console.log("StockTea: Instruments fetch failed: " + err)
                                next() 
                            })
                        }
                        ensureLoaded(function(){
                        console.log("StockTea: Calling searchTradableSymbols for: " + q)
                        upstoxApi.searchTradableSymbols(q, function(results) {
                            console.log("StockTea: Search returned " + results.length + " results")
                            if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                main.dbgprint("Search returned " + results.length + " results for query: " + q)
                            }
                            
                            symbolSuggestions.clear()
                            for (var i = 0; i < results.length; i++) {
                                symbolSuggestions.append(results[i])
                                if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                    main.dbgprint("Added search result: " + results[i].symbol + " - " + results[i].name)
                                }
                            }
                            suggestionsPopup.visible = symbolSuggestions.count > 0
                            
                            console.log("StockTea: Search popup visibility: " + suggestionsPopup.visible + ", results count: " + symbolSuggestions.count)
                            if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                main.dbgprint("Search popup visibility: " + suggestionsPopup.visible + ", results count: " + symbolSuggestions.count)
                            }
                        }, function(error) {
                            console.log("StockTea: Search failed: " + error)
                            if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                main.dbgprint("Search failed for query: " + q + ", error: " + error)
                            }
                            symbolSuggestions.clear();
                            suggestionsPopup.visible = false
                        })
                        })
                }
                }

                Popup {
                    id: suggestionsPopup
                    x: symbolField.x
                    y: symbolField.y + symbolField.height + 4
                    width: symbolField.width
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                    contentItem: ListView {
                        implicitHeight: Math.min(contentHeight, 200)
                        model: symbolSuggestions
                        delegate: PlasmaComponents.ItemDelegate {
                            width: parent ? parent.width : 0
                            text: (model.symbol || "") + (model.name ? (" — " + model.name) : "")
                            onClicked: {
                                symbolField.text = model.symbol
                                nameField.text = model.name || model.symbol
                                selectedInstrument = {
                                    symbol: model.symbol,
                                    name: model.name,
                                    exchange: model.exchange,
                                    instrument_key: model.instrument_key,
                                    isin: model.isin,
                                    segment: model.segment || '',
                                    instrument_type: model.instrument_type || ''
                                }
                                suggestionsPopup.visible = false
                                
                                if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
                                    main.dbgprint("Selected instrument: " + JSON.stringify(selectedInstrument))
                                }
                            }
                        }
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
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator {
                            bottom: 0.01
                            decimals: 2
                        }
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
            Layout.fillHeight: true
            Layout.minimumHeight: 250
            Layout.preferredHeight: Math.max(250, positionsListView.contentHeight + 40)
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                PlasmaComponents.Label {
                    text: i18n("Current Positions (%1)", main.positionsList.count)
                    font.pixelSize: defaultFontPixelSize * 1.1
                    font.bold: true
                    Layout.fillWidth: true
                }

                ListView {
                    id: positionsListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: main.positionsList
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
                                icon.name: "document-edit"
                                onClicked: {
                                    startEditing(model)
                                }
                            }

                            PlasmaComponents.Button {
                                text: i18n("Remove")
                                icon.name: "edit-delete"
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
                        visible: main.positionsList.count === 0
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
        var portfolios = PortfolioModel.getPortfolioFromConfig() || []
        var portfolioIndex = plasmoid.configuration.portfolioIndex || 0
        if (portfolios.length === 0) {
            var p = PortfolioModel.createEmptyPortfolio()
            p.id = "default_portfolio"
            p.name = portfolioNameField.text || i18n("My Portfolio")
            p.currency = 'INR'
            portfolios.push(p)
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        if (portfolioIndex < 0 || portfolioIndex >= portfolios.length) {
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        
        if (portfolioIndex >= 0 && portfolioIndex < portfolios.length) {
            portfolios[portfolioIndex].name = portfolioNameField.text
            portfolios[portfolioIndex].currency = 'INR'
            
            if (PortfolioModel.savePortfolioToConfig(portfolios)) {
                main.currentPortfolio.name = portfolioNameField.text
                main.currentPortfolio.currency = 'INR'
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
        var bp = parseFloat(buyPriceField.text)
        newPosition.buyingPrice = isNaN(bp) ? 0 : bp
        newPosition.currency = 'INR'
        if (selectedInstrument) {
            newPosition.metadata = selectedInstrument
            newPosition.instrument_key = selectedInstrument.instrument_key
            newPosition.exchange = selectedInstrument.exchange
            newPosition.segment = selectedInstrument.segment
        }

        PortfolioModel.calculatePositionMetrics(newPosition)

        var portfolios = PortfolioModel.getPortfolioFromConfig() || []
        var portfolioIndex = plasmoid.configuration.portfolioIndex || 0
        if (portfolios.length === 0) {
            var p = PortfolioModel.createEmptyPortfolio()
            p.id = "default_portfolio"
            p.name = main.currentPortfolio.name || i18n("My Portfolio")
            p.currency = main.currentPortfolio.currency || "INR"
            portfolios.push(p)
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        if (portfolioIndex < 0 || portfolioIndex >= portfolios.length) {
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        
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
        var bp2 = parseFloat(buyPriceField.text)
        updatedPosition.buyingPrice = isNaN(bp2) ? 0 : bp2
        updatedPosition.currency = 'INR'
        if (selectedInstrument) {
            updatedPosition.metadata = selectedInstrument
            updatedPosition.instrument_key = selectedInstrument.instrument_key
            updatedPosition.exchange = selectedInstrument.exchange
            updatedPosition.segment = selectedInstrument.segment
        }

        PortfolioModel.calculatePositionMetrics(updatedPosition)

        var portfolios = PortfolioModel.getPortfolioFromConfig() || []
        var portfolioIndex = plasmoid.configuration.portfolioIndex || 0
        if (portfolios.length === 0) {
            return
        }
        if (portfolioIndex < 0 || portfolioIndex >= portfolios.length) {
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        
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
        var portfolios = PortfolioModel.getPortfolioFromConfig() || []
        var portfolioIndex = plasmoid.configuration.portfolioIndex || 0
        if (portfolios.length === 0) {
            return
        }
        if (portfolioIndex < 0 || portfolioIndex >= portfolios.length) {
            portfolioIndex = 0
            plasmoid.configuration.portfolioIndex = 0
        }
        
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
        selectedInstrument = position.metadata || null
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
        selectedInstrument = null
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
        
        // Test Upstox API initialization
        if (typeof main !== 'undefined' && typeof main.dbgprint === 'function') {
            main.dbgprint("ManageView completed - testing Upstox API initialization")
        }
        
        // Try to load instruments from CSV cache (smaller and easier to parse)
        console.log("StockTea: Attempting to load instruments from CSV cache...")
        var cacheFile = StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/stocktea/instruments.csv"
        console.log("StockTea: Cache file path: " + cacheFile)
        
        // Try to read the CSV cache file
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + cacheFile);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        console.log("StockTea: CSV cache file read, parsing...")
                        var csvText = xhr.responseText
                        console.log("StockTea: CSV text length: " + csvText.length)
                        
                        // Parse CSV using the existing parseInstrumentsCSV function
                        upstoxApi._instruments = upstoxApi.parseInstrumentsCSV(csvText)
                        upstoxApi._lastInstrumentsLoadedAt = Date.now()
                        console.log("StockTea: Loaded " + upstoxApi._instruments.length + " instruments from CSV cache")
                    } catch(e) {
                        console.log("StockTea: Error parsing CSV cache: " + e.message)
                    }
                } else {
                    console.log("StockTea: Cache file not accessible. Please run: bash contents/code/fetch-instruments.sh")
                }
            }
        }
        xhr.send();
    }
}
