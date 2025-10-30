/*
 * StockTea - Compact Item
 * Individual compact display component
 */
import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import "../code/portfolio-model.js" as PortfolioModel

Item {
    id: compactItem

    property bool vertical: false

    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property int iconSize: main.widgetIconSize || 32
    property int fontSize: main.widgetFontSize || 20

    Layout.minimumWidth: vertical ? iconSize : iconSize + textComponent.contentWidth + 10
    Layout.minimumHeight: vertical ? iconSize + textComponent.contentHeight + 10 : iconSize

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 5
        layoutDirection: vertical ? Qt.TopToBottom : Qt.LeftToRight

        PlasmaCore.IconItem {
            id: iconComponent
            source: "finance"
            width: iconSize
            height: iconSize
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
            Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            visible: main.iconVisible !== false
            active: compactItemMouseArea.containsMouse
        }

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: !vertical
            Layout.fillHeight: vertical
            Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            spacing: 0
            visible: main.textVisible !== false

            PlasmaComponents.Label {
                id: portfolioNameText
                text: main.currentPortfolio.name || i18n("Portfolio")
                font.pixelSize: Math.max(fontSize * 0.6, 10)
                font.family: main.widgetFontName
                color: Kirigami.Theme.textColor
                horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
                Layout.fillWidth: !vertical
                Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                id: portfolioValueText
                text: main.portfolioSummaryText || "$0.00"
                font.pixelSize: fontSize
                font.family: main.widgetFontName
                font.bold: true
                color: Kirigami.Theme.textColor
                horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
                Layout.fillWidth: !vertical
                Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            PlasmaComponents.Label {
                id: portfolioChangeText
                text: main.currentPortfolio.totalProfitLoss !== 0 ? 
                      PortfolioModel.formatPercent(main.currentPortfolio.totalProfitLossPercent) : ""
                font.pixelSize: Math.max(fontSize * 0.7, 10)
                font.family: main.widgetFontName
                color: main.currentPortfolio.totalProfitLoss >= 0 ? 
                       Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
                Layout.fillWidth: !vertical
                Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
            }
        }
    }

    MouseArea {
        id: compactItemMouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            main.expanded = !main.expanded
        }

        onEntered: {
            iconComponent.active = true
        }

        onExited: {
            iconComponent.active = false
        }
    }

    // Drop shadow for text (if enabled)
    DropShadow {
        anchors.fill: textColumn
        source: textColumn
        horizontalOffset: 1
        verticalOffset: 1
        radius: 2
        samples: 9
        color: "black"
        spread: 0.3
        visible: main.textDropShadow && !vertical
        opacity: 0.5
    }

    // Drop shadow for icon (if enabled)
    DropShadow {
        anchors.fill: iconComponent
        source: iconComponent
        horizontalOffset: 1
        verticalOffset: 1
        radius: 2
        samples: 9
        color: "black"
        spread: 0.3
        visible: main.iconDropShadow && !vertical
        opacity: 0.5
    }

    // Animation for value changes
    Behavior on portfolioValueText.text {
        ColorAnimation {
            duration: 300
        }
    }

    // Animation for profit/loss changes
    Behavior on portfolioChangeText.color {
        ColorAnimation {
            duration: 300
        }
    }
}
