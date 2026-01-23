//
//  Item.swift
//  MedicationReminder
//
//  Created by Yuangang Sheng on 15.01.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var name: String
    var amount: String
    var isCompleted: Bool
    
    init(timestamp: Date, name: String = "", amount: String = "", isCompleted: Bool = false) {
        self.timestamp = timestamp
        self.name = name
        self.amount = amount
        self.isCompleted = isCompleted
    }
}
