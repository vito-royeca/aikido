//
//  SegmentModel.swift
//  Aikido
//
//  Created by Vito Royeca on 12/14/25.
//

import SwiftData

@Model
final class SegmentModel: Equatable {
    var startTime: Int
    var endTime: Int
    var text: String
    
    init(startTime: Int,
         endTime: Int,
         text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case startTime
        case endTime
        case text
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        startTime = try container.decode(Int.self, forKey: .startTime)
        endTime = try container.decode(Int.self, forKey: .endTime)
        text = try container.decode(String.self, forKey: .text)
    }
}

// MARK: - Codable

extension SegmentModel: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(text, forKey: .text)
    }
}

// MARK: - Helper

extension SegmentModel {
    var description: String {
        get {
            let startDuration: Duration = .milliseconds(startTime)
            let endDuration: Duration = .milliseconds(endTime)
            let startFormat = startDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            let endFormat = endDuration.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            return "[\(startFormat)-\(endFormat)] \(text)"
        }
    }
}
