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
    var downloadURL: String
    var fileName: String
    var order: Int
    
    @Transient  private var _isDownloaded = false
    @Transient var isDownloaded: Bool {
        get {
            _isDownloaded || FileManager.default.fileExists(atPath: fileURL.path())
        }
        set {
            _isDownloaded = newValue
        }
    }

    init(name: String,
         info: String,
         downloadURL: String,
         fileName: String,
         order: Int) {
        self.name = name
        self.info = info
        self.downloadURL = downloadURL
        self.fileName = fileName
        self.order = order
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case name
        case info
        case downloadURL
        case fileName
        case order
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        info = try container.decode(String.self, forKey: .info)
        downloadURL = try container.decode(String.self, forKey: .downloadURL)
        fileName = try container.decode(String.self, forKey: .fileName)
        order = try container.decode(Int.self, forKey: .order)
    }
}

// MARK: - Codable

extension WhisperFile: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(info, forKey: .info)
        try container.encode(downloadURL, forKey: .downloadURL)
        try container.encode(order, forKey: .order)
    }
}

// MARK: - Methods

extension WhisperFile {
    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
}
