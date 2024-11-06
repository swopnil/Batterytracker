import SwiftUI
import SwiftData
import Charts
import CoreLocation
import UIKit
import Foundation


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp) private var items: [Item]
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    let autoRefreshTimer = Timer.publish(
            every: 30,  // Refresh every 30 seconds
            on: .main,
            in: .common
        ).autoconnect()
        


    @State private var showingAddItem = false
    @StateObject private var brightnessObserver = BrightnessObserver()

    @StateObject private var timeManager = TimeManager()

    
    private let locationManager = CLLocationManager()
    private let locationDelegate = LocationManagerDelegate()
    
    
    // Battery monitoring
    @State private var batteryLevel = 0.0
    @State private var isCharging = false
    @State private var estimatedTimeRemaining = ""
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced  // To save battery
    }
    
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                batteryLevel: batteryLevel,
                isCharging: isCharging,
                estimatedTime: estimatedTimeRemaining,
                drainRate: calculateDischargingRate(),
                screenBrightness: brightnessObserver.screenBrightness// Add this
            )
            .refreshable {
                                await refreshData()
                            }
                .tabItem {
                    Label("Home", systemImage: "battery.100")
                }
                .tag(0)
            
            StatsView(items: items)
                .tabItem {
                    Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .onAppear {
            startMonitoring()
            timeManager.requestNotificationPermission()

        }
        .onReceive(timer) { _ in
            updateBatteryInfo()
        }
        .onReceive(autoRefreshTimer) { _ in
                    updateBatteryInfo()
                }
        
    }
    private func refreshData() async {
            // Show refresh indicator
            isRefreshing = true
            
            // Update battery info
            updateBatteryInfo()
            
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Hide refresh indicator
            isRefreshing = false
        }

    
    private func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryInfo()
    }
    
    
    private func updateBatteryInfo() {
        let device = UIDevice.current
        batteryLevel = Double(device.batteryLevel)
        isCharging = device.batteryState == .charging
        
        // Save new reading
        let newItem = Item(
            timestamp: Date(),
            batteryLevel: batteryLevel,
            screenBrightness: Double(UIScreen.main.brightness),
            isLocationActive: CLLocationManager().authorizationStatus != .denied,
            networkType: getNetworkType(),
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            temperature: 0.0, // Would need additional permissions
            dischargingRate: calculateDischargingRate()
        )
        
        modelContext.insert(newItem)
        
        // Calculate estimated time
        estimatedTimeRemaining = calculateTimeRemaining()
        
        let drainRate = calculateDischargingRate()
                timeManager.calculateTimeRemaining(
                    batteryLevel: batteryLevel,
                    drainRate: drainRate
                )
        }
    
    private func getNetworkType() -> String {
        // Implement network type detection
        return "Wi-Fi"
    }
    
    private func calculateDischargingRate() -> Double {
        guard items.count >= 2 else { return 0.0 }
        let last = items[items.count - 1]
        let beforeLast = items[items.count - 2]
        let timeDiff = last.timestamp.timeIntervalSince(beforeLast.timestamp)
        let levelDiff = last.batteryLevel - beforeLast.batteryLevel
        return abs(levelDiff / timeDiff)
    }
    
    private func calculateTimeRemaining() -> String {
        guard !isCharging else { return "Charging" }
        let rate = calculateDischargingRate()
        guard rate > 0 else { return "Calculating..." }
        
        let hoursRemaining = batteryLevel / rate
        return String(format: "%.1f hours remaining", hoursRemaining)
    }
}

struct HomeView: View {
    let batteryLevel: Double
    let isCharging: Bool
    let estimatedTime: String
    let drainRate: Double
    let screenBrightness: Double  // Add this

    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 20) {
                // Battery Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: batteryLevel)
                        .stroke(
                            batteryLevel > 0.2 ? Color.green : Color.red,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(batteryLevel * 100))%")
                            .font(.system(size: 50, weight: .bold))
                        Text(estimatedTime)
                            .font(.subheadline)
                    }
                }
                .padding()
                
                // Time Remaining View (Updated)
                TimeRemainingView(
                    timeRemaining: estimatedTime,
                    batteryLevel: batteryLevel,
                    drainRate: drainRate,
                    isCharging: isCharging
                )
                
                // Status Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatusCard(
                        title: "Charging",
                        value: isCharging ? "Yes" : "No",
                        icon: "bolt.fill",
                        color: isCharging ? .green : .yellow
                    )
                    
                    StatusCard(
                        title: "Mode",
                        value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Low Power" : "Normal",
                        icon: "leaf.fill",
                        color: .green
                    )
                    
                    StatusCard(
                        title: "Screen",
                        value: "\(Int(screenBrightness * 100))%",  // Use the new property
                        icon: "sun.max.fill",
                        color: .orange
                    )
                    
                    StatusCard(
                        title: "Network",
                        value: "Wi-Fi",
                        icon: "wifi",
                        color: .blue
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Battery Status")
        
        .refreshable {
                    // This enables pull-to-refresh
                    await Task.sleep(1_000_000_000) // 1 second delay
                }
    }
}
struct TimeRemainingView: View {
    let timeRemaining: String
    let batteryLevel: Double
    let drainRate: Double
    let isCharging: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(isCharging ? "Time to Full Charge" : "Time Remaining")
                .font(.headline)
            
            Text(isCharging ? calculateChargingTime() : timeRemaining)
                .font(.system(size: 28, weight: .bold))
            
            HStack(spacing: 20) {
                VStack {
                    Text("Current Level")
                        .font(.caption)
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.title3)
                        .bold()
                }
                
                VStack {
                    Text(isCharging ? "Charge Rate" : "Drain Rate")
                        .font(.caption)
                    Text(isCharging ?
                         String(format: "+%.1f%%/hr", getChargingRate() * 100) :
                         String(format: "%.1f%%/hr", drainRate * 100))
                        .font(.title3)
                        .bold()
                        .foregroundColor(isCharging ? .green : .primary)
                }
            }
            
            if isCharging {
                Text("Full charge at \(estimateFullChargeTime())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private func getChargingRate() -> Double {
        // Average charging rates based on charging type
        // These are approximate values, could be made more accurate
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return 0.30 // 30% per hour in low power mode
        } else {
            return 0.45 // 45% per hour in normal mode
        }
    }
    
    private func calculateChargingTime() -> String {
        let remainingPercent = 1.0 - batteryLevel
        let chargeRate = getChargingRate()
        let hoursToFull = remainingPercent / chargeRate
        
        if hoursToFull < 1 {
            let minutes = Int(hoursToFull * 60)
            return "\(minutes)m to full"
        } else {
            let hours = Int(hoursToFull)
            let minutes = Int((hoursToFull - Double(hours)) * 60)
            return "\(hours)h \(minutes)m to full"
        }
    }
    
    private func estimateFullChargeTime() -> String {
        let remainingPercent = 1.0 - batteryLevel
        let chargeRate = getChargingRate()
        let hoursToFull = remainingPercent / chargeRate
        
        let fullChargeDate = Date().addingTimeInterval(hoursToFull * 3600)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        return formatter.string(from: fullChargeDate)
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title2)
                    .bold()
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatsView: View {
    let items: [Item]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Battery Level Chart
                Chart(items) { item in
                    LineMark(
                        x: .value("Time", item.timestamp),
                        y: .value("Level", item.batteryLevel)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .padding()
                
                // Usage Stats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Usage Statistics")
                        .font(.headline)
                    
                    Text("Average discharge rate: \(averageDischargeRate())%/hour")
                    Text("Screen time impact: \(screenTimeImpact())%")
                    Text("Network impact: \(networkImpact())%")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Statistics")
    }
    
    private func averageDischargeRate() -> String {
        guard items.count >= 2 else { return "0.0" }
        // Calculate average discharge rate
        return "2.5" // Example value
    }
    
    private func screenTimeImpact() -> String {
        return "15" // Example value
    }
    
    private func networkImpact() -> String {
        return "10" // Example value
    }
}

struct SettingsView: View {
    @AppStorage("notifyLowBattery") private var notifyLowBattery = true
    @AppStorage("lowBatteryThreshold") private var lowBatteryThreshold = 20.0
    @AppStorage("notifyAt10Min") private var notifyAt10Min = true
    @AppStorage("notifyAt5Min") private var notifyAt5Min = true
    

    var body: some View {
        Form {
            Section("Battery Warnings") {
                            Toggle("Notify at 10 minutes remaining", isOn: $notifyAt10Min)
                            Toggle("Notify at 5 minutes remaining", isOn: $notifyAt5Min)
                        }

            Section("Notifications") {
                Toggle("Low Battery Alerts", isOn: $notifyLowBattery)
                if notifyLowBattery {
                    Slider(value: $lowBatteryThreshold, in: 5...30, step: 5) {
                        Text("Alert Threshold")
                    } minimumValueLabel: {
                        Text("5%")
                    } maximumValueLabel: {
                        Text("30%")
                    }
                }
            }
            
            Section("About") {
                Text("Battery Tracker v1.0")
                Text("© 2024 Your Name")
            }
        }
        .navigationTitle("Settings")
    }
}
