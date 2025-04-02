//
//  WhisperManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation
import AVFoundation
import SwiftData

class WhisperManager {
    static let shared = WhisperManager()
    
    private let defaultWhisperName = "tiny"
    
    private var whisperContext: WhisperContext?
    private var loadedWhisperFile: WhisperFile?

    private init() {
        
    }
    
    @MainActor
    func loadDefault() {
        let descriptor = FetchDescriptor<WhisperFile>(predicate: #Predicate { $0.name == defaultWhisperName })
        
        if let whisperFile = (try? DataManager.shared.modelContainer.mainContext.fetch(descriptor))?.first {
            load(whisperFile)
        }
    }

    func load(_ whisperFile: WhisperFile) {
        if let loadedWhisperFile,
              loadedWhisperFile.name == whisperFile.name {
            return
        }

        do {
            copyBundle(name: "ggml-\(whisperFile.name).bin")
            copyBundle(name: "ggml-\(whisperFile.name)-encoder.mlmodelc")
            
            whisperContext = nil
            whisperContext = try WhisperContext.createContext(path: whisperFile.localModelURL.path())
            
            whisperFile.isDownloaded = true
            self.loadedWhisperFile = whisperFile
            print("whisper loaded successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func copyBundle(name: String) {
        if let resPath = Bundle.main.resourcePath {
            do {
                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let filteredFiles = dirContents.filter{ $0.starts(with: name) }

                if let documentsURL {
                    for fileName in filteredFiles {
                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
                        let destURL = documentsURL.appendingPathComponent(fileName)
                        
                        do {
                            if !FileManager.default.fileExists(atPath: destURL.path()) {
                                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                            }
                        }
                        catch {
                            print(error)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    func transcribeAudio(url: URL) async -> String? {
        await loadDefault()

        guard let whisperContext else {
            return nil
        }
        
        do {
            let data = try readAudioSamples(url)
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            return text
        } catch {
            print(error)
            return nil
        }
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        return try decodeWaveFile(url)
    }
    
    private func decodeWaveFile(_ url: URL) throws -> [Float] {
        let data = try Data(contentsOf: url)
        let floats = stride(from: 44, to: data.count, by: 2).map {
            return data[$0..<$0 + 2].withUnsafeBytes {
                let short = Int16(littleEndian: $0.load(as: Int16.self))
                return max(-1.0, min(Float(short) / 32767.0, 1.0))
            }
        }
        return floats
    }
    
    func deleteRecording(url: URL) {
        let lastPath = url.path().components(separatedBy: "/").last ?? ""
        let savedPath = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0].appendingPathComponent(lastPath.removingPercentEncoding ?? lastPath)
        
        do {
            if FileManager.default.fileExists(atPath: savedPath.path) {
                try FileManager.default.removeItem(at: savedPath)
            }
        } catch {
            print(error)
        }
    }

    @MainActor
    func saveRecording(url: URL, transcription: String) {
        let lastPath = url.path().components(separatedBy: "/").last ?? ""
        let title = lastPath.removingPercentEncoding ?? lastPath
        var copiedFileName: String?
        var originalPath: String?
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0]
        if url.path().hasPrefix(documentsDir.path()) {
            copiedFileName = title
        } else {
            originalPath = url.path()
        }
        
        let recording = Recording(title: title,
                                  timestamp: nil,
                                  length: 0,
                                  copiedFileName: copiedFileName,
                                  originalPath: originalPath)
        recording.transcription = transcription

        // get the creationDate
        do {
            if let timestamp = try url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                recording.timestamp = timestamp
            }
        } catch {
            print("\(#function) Error: \(error)")
        }
        
        // get the length
        Task {
            let asset = AVURLAsset(url: url, options: nil)
            let (duration, _) = try await asset.load(.duration, .metadata)
            recording.length = duration.seconds
            
            DataManager.shared.modelContainer.mainContext.insert(recording)
            do {
                try DataManager.shared.modelContainer.mainContext.save()
            } catch {
                print(error)
            }
        }
    }
}
