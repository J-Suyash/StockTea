/*
 * StockTea - General Configuration
 * General settings configuration page
 */
import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_refreshIntervalMin: configRefreshInterval.value
    property alias cfg_debugLogging: configDebugLogging.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        PlasmaComponents.Label {
            text: i18n("Refresh Interval")
            Kirigami.FormData.label: i18n("Data Refresh:")
        }

        SpinBox {
            id: configRefreshInterval
            Kirigami.FormData.label: ""
            from: 1
            to: 60
            value: plasmoid.configuration.refreshIntervalMin
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
            checked: plasmoid.configuration.debugLogging
        }

        PlasmaComponents.Label {
            text: i18n("Enable detailed logging for troubleshooting")
            Kirigami.FormData.label: ""
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
    }

    function resetToDefaults() {
        configRefreshInterval.value = 5
        configDebugLogging.checked = false
    }
}