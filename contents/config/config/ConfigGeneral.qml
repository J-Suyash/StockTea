/*
 * StockTea - General Configuration
 * General settings configuration page
 */
import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    anchors.fill: parent

    property alias cfg_refreshIntervalMin: configRefreshInterval.value
    property alias cfg_debugLogging: configDebugLogging.checked
    property alias cfg_desktopMode: configDesktopMode.currentIndex
    property alias cfg_widgetFontName: configWidgetFontName.text
    property alias cfg_widgetFontSize: configWidgetFontSize.value

    PlasmaComponents.Label {
        text: i18n("Refresh Interval")
        Kirigami.FormData.label: i18n("Data Refresh:")
    }

    SpinBox {
        id: configRefreshInterval
        Kirigami.FormData.label: ""
        from: 1
        to: 60
        value: plasmoid.configuration.refreshIntervalMin || 5
        suffix: i18n(" minutes")
    }

    PlasmaComponents.Label {
        text: i18n("How often to refresh stock data from the API")
        Kirigami.FormData.label: ""
    }

    Item {
        height: Kirigami.Units.largeSpacing
    }

    PlasmaComponents.CheckBox {
        id: configDebugLogging
        Kirigami.FormData.label: i18n("Debug Logging:")
        text: i18n("Enable debug logging")
        checked: plasmoid.configuration.debugLogging || false
    }

    PlasmaComponents.Label {
        text: i18n("Enable detailed logging for troubleshooting")
        Kirigami.FormData.label: ""
    }

    Item {
        height: Kirigami.Units.largeSpacing
    }

    PlasmaComponents.Label {
        text: i18n("Desktop Mode")
        Kirigami.FormData.label: i18n("Display:")
    }

    ComboBox {
        id: configDesktopMode
        Kirigami.FormData.label: ""
        model: [
            { text: i18n("Compact"), value: 0 },
            { text: i18n("Full"), value: 1 }
        ]
        textRole: "text"
        valueRole: "value"
        currentIndex: plasmoid.configuration.desktopMode || 0
    }

    Item {
        height: Kirigami.Units.largeSpacing
    }

    PlasmaComponents.Label {
        text: i18n("Widget Font")
        Kirigami.FormData.label: i18n("Appearance:")
    }

    TextField {
        id: configWidgetFontName
        Kirigami.FormData.label: ""
        placeholderText: i18n("Default system font")
        text: plasmoid.configuration.widgetFontName || ""
    }

    SpinBox {
        id: configWidgetFontSize
        Kirigami.FormData.label: i18n("Font Size:")
        from: 8
        to: 32
        value: plasmoid.configuration.widgetFontSize || 20
        suffix: i18n(" px")
    }

    Item {
        height: Kirigami.Units.largeSpacing
    }

    PlasmaComponents.Button {
        Kirigami.FormData.label: ""
        text: i18n("Reset to Defaults")
        onClicked: {
            resetToDefaults()
        }
    }

    function resetToDefaults() {
        configRefreshInterval.value = 5
        configDebugLogging.checked = false
        configDesktopMode.currentIndex = 0
        configWidgetFontName.text = ""
        configWidgetFontSize.value = 20
    }
}