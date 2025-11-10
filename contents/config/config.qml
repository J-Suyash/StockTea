import QtQuick 2.15
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: 'preferences-system-time'
        source: 'config/ConfigGeneral.qml'
    }
    ConfigCategory {
        name: i18n("API")
        icon: 'internet-services'
        source: 'config/ConfigAPI.qml'
    }
}