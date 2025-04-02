//
//  WhisperFile.swift
//  Aikido
//
//  Created by Vito Royeca on 3/26/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class WhisperFile {
    var name: String
    var info: String
    var modelURL: String
    var coreMLModelURL: String
    var order: Int
    var isDownloaded: Bool
    
    init(name: String,
         info: String,
         modelURL: String,
         coreMLModelURL: String,
         order: Int,
         isDownloaded: Bool = false) {
        self.name = name
        self.info = info
        self.modelURL = modelURL
        self.coreMLModelURL = coreMLModelURL
        self.order = order
        self.isDownloaded = isDownloaded
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case name
        case info
        case modelURL
        case coreMLModelURL
        case order
        case isDownloaded
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        info = try container.decode(String.self, forKey: .info)
        modelURL = try container.decode(String.self, forKey: .modelURL)
        coreMLModelURL = try container.decode(String.self, forKey: .coreMLModelURL)
        order = try container.decode(Int.self, forKey: .order)
        isDownloaded = try container.decode(Bool.self, forKey: .isDownloaded)
    }
}

// MARK: - Codable

extension WhisperFile: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(info, forKey: .info)
        try container.encode(modelURL, forKey: .modelURL)
        try container.encode(coreMLModelURL, forKey: .coreMLModelURL)
        try container.encode(order, forKey: .order)
        try container.encode(isDownloaded, forKey: .isDownloaded)
    }
}

// MARK: - Helper

extension WhisperFile {
    var localModelURL: URL {
        let lastPath = modelURL.components(separatedBy: "/").last ?? ""
        return FileManager.default.urls(for: .documentDirectory,
                                        in: .userDomainMask)[0].appendingPathComponent(lastPath)
    }
    
    var localCoreMLModelURL: URL {
        let lastPath = (coreMLModelURL.components(separatedBy: "/").last ?? "")
            .replacingOccurrences(of: ".zip?download=true", with: "")
        return FileManager.default.urls(for: .documentDirectory,
                                        in: .userDomainMask)[0].appendingPathComponent(lastPath)
    }
}
