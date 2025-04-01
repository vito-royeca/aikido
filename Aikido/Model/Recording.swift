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
    var copiedFileName: String?
    var originalPath: String?
    var transcription: String?
    var summary: String?

    init(title: String, timestamp: Date?, length: Double, copiedFileName: String?, originalPath: String?) {
        self.title = title
        self.timestamp = timestamp
        self.length = length
        self.copiedFileName = copiedFileName
        self.originalPath = originalPath
    }
}

// MARK: - Helper

extension Recording {
    var copiedFileURL: URL? {
        guard let copiedFileName else {
            return nil
        }
        
        return FileManager.default.urls(for: .documentDirectory,
                                        in: .userDomainMask)[0].appendingPathComponent(copiedFileName)
    }
    
    var originalPathURL: URL? {
        guard let originalPath else {
            return nil
        }
        
        return URL(string: originalPath)
    }

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
