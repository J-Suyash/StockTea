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

    // Expose internal controls for external access (e.g., PositionItem)
    property alias mainStackView: mainStackView
    property alias mainTabBar: mainTabBar

    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property double footerHeight: defaultFontPixelSize
    property double tabBarHeight: defaultFontPixelSize * 2.5
    property double headerHeight: defaultFontPixelSize * 2
    property string fullRepresentationAlias: main.fullRepresentationAlias

    // Dynamic sizing based on content and available space
    implicitWidth: 700
    implicitHeight: Math.max(500, headerHeight + tabBarHeight + 300 + footerHeight + 40)

    Layout.minimumWidth: 500
    Layout.minimumHeight: 400
    Layout.preferredWidth: 700
    Layout.preferredHeight: 600
    Layout.maximumWidth: -1  // No maximum width constraint
    Layout.maximumHeight: -1  // No maximum height constraint

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
        height: headerHeight
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
        anchors.topMargin: 5
        anchors.margins: 10
        height: tabBarHeight
        Layout.minimumHeight: tabBarHeight
        Layout.preferredHeight: tabBarHeight
        Layout.maximumHeight: tabBarHeight

        TabButton {
            text: i18n("Portfolio")
            icon.source: "./piggy-bank-icon.svg"
        }
        TabButton {
            text: i18n("Chart")
            icon.name: "application-x-chart"
        }
        TabButton {
            text: i18n("Manage")
            icon.name: "applications-system"
        }
            TabButton {
                text: i18n("Logs")
                icon.name: "view-list-details"
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
            Layout.preferredWidth: reloadLabel.contentWidth + defaultFontPixelSize + 30
            Layout.preferredHeight: footerHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Kirigami.Icon {
                    source: "./piggy-bank-icon.svg"
                    Layout.preferredWidth: defaultFontPixelSize
                    Layout.preferredHeight: defaultFontPixelSize
                }

                PlasmaComponents.Label {
                    id: reloadLabel
                    text: i18n("Reload")
                    font.pixelSize: defaultFontPixelSize * 0.9
                }
            }

            onEntered: reloadLabel.font.underline = true
            onExited: reloadLabel.font.underline = false

            onClicked: main.loadDataFromInternet()
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
