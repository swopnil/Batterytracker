//
//  TimeManager.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//

// TimeManager.swift
import Foundation
import UserNotifications

class TimeManager: ObservableObject {
    @Published var timeRemaining: String = "Calculating..."
    @Published var minutesRemaining: Double = 0
    private var hasNotified10Min = false
    private var hasNotified5Min = false
    
    func calculateTimeRemaining(batteryLevel: Double, drainRate: Double) {
        guard drainRate > 0 else { return }
        
        // Convert to minutes
        minutesRemaining = (batteryLevel * 100) / (drainRate * 60)
        
        if minutesRemaining >= 60 {
            let hours = Int(minutesRemaining / 60)
            let mins = Int(minutesRemaining.truncatingRemainder(dividingBy: 60))
            timeRemaining = "\(hours)h \(mins)m remaining"
        } else {
            timeRemaining = "\(Int(minutesRemaining))m remaining"
        }
        
        checkAndNotify()
    }
    
    private func checkAndNotify() {
        // Check for 10 minute warning
        if minutesRemaining <= 10 && !hasNotified10Min {
            sendNotification(minutes: 10)
            hasNotified10Min = true
        }
        
        // Check for 5 minute warning
        if minutesRemaining <= 5 && !hasNotified5Min {
            sendNotification(minutes: 5)
            hasNotified5Min = true
        }
        
        // Reset flags if battery level increases
        if minutesRemaining > 10 {
            hasNotified10Min = false
            hasNotified5Min = false
        }
    }
    
    private func sendNotification(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Battery Warning"
        content.body = "Approximately \(minutes) minutes of battery remaining"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "battery-\(minutes)min",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
}
