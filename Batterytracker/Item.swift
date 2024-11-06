// Item.swift
import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var batteryLevel: Double
    var screenBrightness: Double
    var isLocationActive: Bool
    var networkType: String
    var isLowPowerMode: Bool
    var temperature: Double
    var dischargingRate: Double
    
    init(
        timestamp: Date = Date(),
        batteryLevel: Double = 0.0,
        screenBrightness: Double = 0.0,
        isLocationActive: Bool = false,
        networkType: String = "Unknown",
        isLowPowerMode: Bool = false,
        temperature: Double = 0.0,
        dischargingRate: Double = 0.0
    ) {
        self.timestamp = timestamp
        self.batteryLevel = batteryLevel
        self.screenBrightness = screenBrightness
        self.isLocationActive = isLocationActive
        self.networkType = networkType
        self.isLowPowerMode = isLowPowerMode
        self.temperature = temperature
        self.dischargingRate = dischargingRate
    }
}
