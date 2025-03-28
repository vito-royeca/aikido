//
//  Recording.swift
//  Aikido
//
//  Created by Vito Royeca on 3/26/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Recording {
    var title: String
    var timestamp: Date
    var length: Float
//    var audioPath: NSURL?
//    var location: CLLocation?
    var transcription: String?
    var summary: String?

    init(title: String, timestamp: Date) {
        self.title = title
        self.timestamp = timestamp
        self.length = 0
    }
}
