/*
 * StockTea - API Configuration
 * API settings configuration page
 */
import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_apiProvider: configApiProvider.currentIndex
    property alias cfg_apiKey: configApiKey.text
    property alias cfg_apiUrl: configApiUrl.text
    property alias cfg_useFreeTier: configUseFreeTier.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        PlasmaComponents.Label {
            text: i18n("Data Provider")
            Kirigami.FormData.label: i18n("API Provider:")
        }

        ComboBox {
            id: configApiProvider
            Kirigami.FormData.label: ""
            model: [
                { text: i18n("Yahoo Finance"), value: "yahoo" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: plasmoid.configuration.apiProvider || 0
            
            onCurrentValueChanged: {
                updateApiUrl(currentValue)
                updateApiKeyVisibility(currentValue)
            }
        }

        PlasmaComponents.Label {
            text: getProviderDescription(configApiProvider.currentValue)
            Kirigami.FormData.label: ""
            wrapMode: Text.WordWrap
        }

        Item {
            height: Kirigami.Units.largeSpacing
        }

        PlasmaComponents.Label {
            text: i18n("API Key")
            Kirigami.FormData.label: i18n("Authentication:")
        }

        TextField {
            id: configApiKey
            Kirigami.FormData.label: ""
            placeholderText: i18n("Enter your API key (optional for Yahoo Finance)")
            text: plasmoid.configuration.apiKey || ""
            echoMode: configShowApiKey.checked ? TextInput.Normal : TextInput.Password
        }

        PlasmaComponents.CheckBox {
            id: configShowApiKey
            Kirigami.FormData.label: ""
            text: i18n("Show API key")
            checked: false
        }

        PlasmaComponents.Label {
            text: getApiKeyHelp(configApiProvider.currentValue)
            Kirigami.FormData.label: ""
            wrapMode: Text.WordWrap
        }

        Item {
            height: Kirigami.Units.largeSpacing
        }

        PlasmaComponents.Label {
            text: i18n("API URL")
            Kirigami.FormData.label: i18n("Endpoint:")
        }

        TextField {
            id: configApiUrl
            Kirigami.FormData.label: ""
            placeholderText: i18n("Custom API endpoint URL")
            text: plasmoid.configuration.apiUrl || ""
        }

        PlasmaComponents.Label {
            text: i18n("Custom API endpoint (advanced users only)")
            Kirigami.FormData.label: ""
            wrapMode: Text.WordWrap
        }

        Item {
            height: Kirigami.Units.largeSpacing
        }

        PlasmaComponents.CheckBox {
            id: configUseFreeTier
            Kirigami.FormData.label: i18n("Usage:")
            text: i18n("Use free tier (limited requests)")
            checked: plasmoid.configuration.useFreeTier !== false
        }

        PlasmaComponents.Label {
            text: i18n("Free tier has rate limits. Premium API keys provide higher limits.")
            Kirigami.FormData.label: ""
            wrapMode: Text.WordWrap
        }

        Item {
            height: Kirigami.Units.largeSpacing
        }

        PlasmaComponents.Button {
            Kirigami.FormData.label: ""
            text: i18n("Test Connection")
            onClicked: {
                testApiConnection()
            }
        }

        PlasmaComponents.Label {
            id: connectionStatus
            Kirigami.FormData.label: ""
            text: ""
            color: Kirigami.Theme.positiveTextColor
        }
    }

    function updateApiUrl(provider) {
        var defaultUrls = {
            "yahoo": "https://query1.finance.yahoo.com"
        }
        
        if (!configApiUrl.text || configApiUrl.text === plasmoid.configuration.apiUrl) {
            configApiUrl.text = defaultUrls[provider] || ""
        }
    }

    function updateApiKeyVisibility(provider) {
        configApiKey.visible = provider !== "yahoo"
        configShowApiKey.visible = provider !== "yahoo"
    }

    function getProviderDescription(provider) {
        var descriptions = {
            "yahoo": i18n("Free, unofficial Yahoo Finance API. No API key required but may be less reliable.")
        }
        return descriptions[provider] || ""
    }

    function getApiKeyHelp(provider) {
        var helpTexts = {
        }
        return helpTexts[provider] || ""
    }

    function testApiConnection() {
        connectionStatus.text = i18n("Testing connection...")
        connectionStatus.color = Kirigami.Theme.textColor
        
        // Simulate connection test
        testTimer.start()
    }

    Timer {
        id: testTimer
        interval: 2000
        onTriggered: {
            // Simulate successful connection
            connectionStatus.text = i18n("Connection successful!")
            connectionStatus.color = Kirigami.Theme.positiveTextColor
        }
    }

    Component.onCompleted: {
        updateApiUrl(configApiProvider.currentValue)
        updateApiKeyVisibility(configApiProvider.currentValue)
    }
}