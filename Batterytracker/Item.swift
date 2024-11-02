//
//  Item.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
