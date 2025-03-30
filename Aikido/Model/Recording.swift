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
    var timestamp: Date?
    var length: Double
    var audioPath: String?
    var transcription: String?
    var summary: String?
//    var location: CLLocation?

    init(title: String, timestamp: Date?, length: Double, audioPath: String?) {
        self.title = title
        self.timestamp = timestamp
        self.length = length
        self.audioPath = audioPath
    }
}

// MARK: - Helper

extension Recording {
    var formattedLength: String {
        get {
            let duration: Duration = .seconds(length)
            let string = duration.formatted(.units(width: .narrow))
            return string
        }
    }
    
    var formattedTimestamp: String {
        get {
            guard let timestamp = self.timestamp else {
                return ""
            }
            return DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short)
        }
    }
}
