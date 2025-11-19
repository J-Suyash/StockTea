// Instruments loader - loads instruments data from cache file
// This file is imported by ManageView.qml

.pragma library

var instrumentsData = []
var lastLoadedAt = 0

function loadInstruments(cacheLocation) {
    var instrumentsPath = cacheLocation + "/stocktea/instruments.js"

    try {
        // Include the instruments JavaScript file
        Qt.include(instrumentsPath)

        // Check if INSTRUMENTS_DATA was loaded
        if (typeof INSTRUMENTS_DATA !== 'undefined') {
            instrumentsData = INSTRUMENTS_DATA
            lastLoadedAt = Date.now()
            return {
                success: true,
                count: instrumentsData.length,
                data: instrumentsData
            }
        } else {
            return {
                success: false,
                error: "INSTRUMENTS_DATA not found in file"
            }
        }
    } catch (e) {
        return {
            success: false,
            error: e.message
        }
    }
}

function getInstruments() {
    return instrumentsData
}
