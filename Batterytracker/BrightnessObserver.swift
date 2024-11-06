//
//  BrightnessObserver.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//

// BrightnessObserver.swift
import UIKit
import Combine

class BrightnessObserver: ObservableObject {
    @Published var screenBrightness: Double = UIScreen.main.brightness
    
    init() {
        // Observe screen brightness changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(brightnessDidChange),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func brightnessDidChange() {
        screenBrightness = UIScreen.main.brightness
    }
}
