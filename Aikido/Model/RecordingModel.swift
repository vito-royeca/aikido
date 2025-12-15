//
//  RecordingModel.swift
//  Aikido
//
//  Created by Vito Royeca on 3/26/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class RecordingModel {
    var title: String
    var timestamp: Date?
    var latitude: Double?
    var longitude: Double?
    var placeName: String?
    var length: Double
    var copiedFileName: String?
    var originalPath: String?
    var transcription: String?
    var transcriptionWithTime: String?
    var summary: String?
    
    @Relationship(deleteRule: .cascade)
    var segments = [SegmentModel]()

    init(title: String,
         timestamp: Date?,
         latitude: Double?,
         longitude: Double?,
         placeName: String?,
         length: Double,
         copiedFileName: String?,
         originalPath: String?) {
        self.title = title
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.length = length
        self.copiedFileName = copiedFileName
        self.originalPath = originalPath
    }
    
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case title
        case timestamp
        case latitude
        case longitude
        case placeName
        case length
        case copiedFileName
        case originalPath
        case transcription
        case transcriptionWithTime
        case summary
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decode(String.self, forKey: .title)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        placeName = try container.decode(String.self, forKey: .placeName)
        length = try container.decode(Double.self, forKey: .length)
        copiedFileName = try container.decode(String.self, forKey: .copiedFileName)
        originalPath = try container.decode(String.self, forKey: .originalPath)
    }
}

// MARK: - Codable

extension RecordingModel: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(placeName, forKey: .placeName)
        try container.encode(length, forKey: .length)
        try container.encode(copiedFileName, forKey: .copiedFileName)
        try container.encode(originalPath, forKey: .originalPath)
    }
}

// MARK: - Helper

extension RecordingModel {
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
    
    func generateTranscriptions() {
        var transcription: String = ""
        var transcriptionWithTime: String = ""
        
        for segment in segments {
            transcription.append("\(segment.text)\n")
            transcriptionWithTime.append("\(segment.description)\n")
        }
        
        self.transcription = transcription
        self.transcriptionWithTime = transcriptionWithTime
    }
}
