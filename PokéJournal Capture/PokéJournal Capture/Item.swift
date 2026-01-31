//
//  Item.swift
//  PokéJournal Capture
//
//  Created by Piotr Großmann on 31.01.26.
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
