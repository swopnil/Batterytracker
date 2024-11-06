//
//  BackgroundManager.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//

// BackgroundManager.swift
import Foundation
import BackgroundTasks

class BackgroundManager {
    static let shared = BackgroundManager()
    private let backgroundTaskIdentifier = "com.yourdomain.batterytracker.refresh"
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleNextBackgroundTask()
        // Update battery info here
        task.setTaskCompleted(success: true)
    }
    
    func scheduleNextBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
