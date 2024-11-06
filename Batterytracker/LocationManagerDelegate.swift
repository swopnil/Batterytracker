//
//  LocationManagerDelegate.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//
import Foundation
import CoreLocation

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access granted")
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
