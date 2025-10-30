/*
 * StockTea - Full Representation
 * Detailed portfolio view with positions and charts
 *
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "../code/portfolio-model.js" as PortfolioModel

Item {
    id: fullRepresentation
    objectName: "fullRepresentation"

    property int widgetWidth: main.widgetWidth || 600
    property int widgetHeight: main.widgetHeight || 400

    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property double footerHeight: defaultFontPixelSize

    property int headingHeight: defaultFontPixelSize * 2
    property string fullRepresentationAlias: main.fullRepresentationAlias

    implicitWidth: widgetWidth
    implicitHeight: headingHeight + widgetHeight + footerHeight + 20

    Layout.minimumWidth: widgetWidth
    Layout.minimumHeight: headingHeight + widgetHeight + footerHeight + 20
    Layout.preferredWidth: widgetWidth
    Layout.preferredHeight: headingHeight + widgetHeight + footerHeight + 20

    onFullRepresentationAliasChanged: {
        var t = main.fullRepresentationAlias
        currentLocationText.text = t
    }

    // Header with portfolio name and navigation
    RowLayout {
        id: headerLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        height: headingHeight
        spacing: 10

        PlasmaComponents.Label {
            id: currentLocationText
            text: ""
            font.pixelSize: defaultFontPixelSize * 1.2
            font.bold: true
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
        }

        PlasmaComponents.Button {
            id: prevPortfolioButton
            text: "<<"
            visible: main.portfoliosCount > 1
            onClicked: {
                main.setNextPortfolio(false, "-")
            }
            ToolTip.text: i18n("Previous Portfolio")
            ToolTip.visible: hovered
        }

        PlasmaComponents.Button {
            id: nextPortfolioButton
            text: ">>"
            visible: main.portfoliosCount > 1
            onClicked: {
                main.setNextPortfolio(false, "+")
            }
            ToolTip.text: i18n("Next Portfolio")
            ToolTip.visible: hovered
        }
    }

    // Main content area with tabs
    TabBar {
        id: mainTabBar
        objectName: "mainTabBar"
        anchors.top: headerLayout.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10

        TabButton {
            text: i18n("Portfolio")
        }
        TabButton {
            text: i18n("Chart")
        }
        TabButton {
            text: i18n("Manage")
        }
            TabButton {
                text: i18n("Logs")
            }
    }

    StackView {
        id: mainStackView
        objectName: "mainStackView"
        anchors.top: mainTabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerArea.top
        anchors.margins: 10

        initialItem: portfolioView
    }

    Component {
        id: portfolioView
        PortfolioView {
        }
    }
    
    Component {
        id: chartView
        ChartView {
        }
    }
    
    Component {
        id: manageView
        ManageView {
        }
    }

    Component {
        id: logsView
        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label {
                        text: i18n("Network Logs (%1)", main.networkLogs ? main.networkLogs.count : 0)
                        font.pixelSize: defaultFontPixelSize * 1.1
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    PlasmaComponents.Button {
                        text: i18n("Clear")
                        onClicked: main.clearNetworkLogs()
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: main.networkLogs
                    delegate: RowLayout {
                        width: parent ? parent.width : 0
                        spacing: 8
                        PlasmaComponents.Label { text: (model.timestamp || "").toString(); font.pixelSize: defaultFontPixelSize * 0.8; color: Kirigami.Theme.disabledTextColor; Layout.preferredWidth: 150 }
                        PlasmaComponents.Label { text: (model.method || "GET"); font.pixelSize: defaultFontPixelSize * 0.9; Layout.preferredWidth: 50 }
                        PlasmaComponents.Label { text: (model.status || "").toString(); font.pixelSize: defaultFontPixelSize * 0.9; Layout.preferredWidth: 50; color: (model.ok ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor) }
                        PlasmaComponents.Label { text: (model.durationMs ? model.durationMs + 'ms' : ''); font.pixelSize: defaultFontPixelSize * 0.9; Layout.preferredWidth: 70 }
                        PlasmaComponents.Label { text: (model.url || ""); font.pixelSize: defaultFontPixelSize * 0.9; Layout.fillWidth: true; wrapMode: Text.NoWrap; elide: Text.ElideRight }
                    }
                }
            }
        }
    }

    // Connect to TabBar currentIndex changes
    Connections {
        target: mainTabBar
        function onCurrentIndexChanged() {
            switch (mainTabBar.currentIndex) {
                case 0:
                    mainStackView.replace(portfolioView)
                    break
                case 1:
                    mainStackView.replace(chartView)
                    break
                case 2:
                    mainStackView.replace(manageView)
                    break
                    case 3:
                        mainStackView.replace(logsView)
                        break
            }
        }
    }

    // Footer with reload and status information
    RowLayout {
        id: footerArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        height: footerHeight
        spacing: 10

        MouseArea {
            id: reloadArea
            Layout.preferredWidth: reloadText.contentWidth + 20
            Layout.preferredHeight: footerHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            PlasmaComponents.Label {
                id: reloadText
                anchors.centerIn: parent
                text: '\u21bb ' + i18n("Reload")
                font.pixelSize: defaultFontPixelSize * 0.9
            }

            onEntered: {
                reloadText.font.underline = true
            }

            onExited: {
                reloadText.font.underline = false
            }

            onClicked: {
                main.loadDataFromInternet()
            }
        }

        PlasmaComponents.Label {
            id: lastReloadedText
            text: main.lastReloadedText
            font.pixelSize: defaultFontPixelSize * 0.9
            Layout.fillWidth: true
        }

        PlasmaComponents.Label {
            id: statusText
            text: PortfolioModel.isMarketOpen() ? i18n("Market Open") : i18n("Market Closed")
            font.pixelSize: defaultFontPixelSize * 0.9
            color: PortfolioModel.isMarketOpen() ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
        }
    }

    // Loading overlay
    PlasmaComponents.BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        running: main.loadingData.loadingDatainProgress
        visible: running
    }

    // Error message display
    PlasmaComponents.Label {
        id: errorText
        anchors.centerIn: parent
        text: i18n("Failed to load portfolio data")
        font.pixelSize: defaultFontPixelSize
        color: Kirigami.Theme.negativeTextColor
        visible: main.loadingData.loadingError && !loadingIndicator.visible
    }

    Component.onCompleted: {
        dbgprint2("FullRepresentation")
        dbgprint(main.currentPortfolio.name)
    }
}
