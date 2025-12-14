//
//  WhisperManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation
import AVFoundation
import SwiftData
import LLM

class Summarizer: LLM {
    convenience init() {
        let url = Bundle.main.url(forResource: "tinyllama-1.1b-chat-v1.0.Q2_K", withExtension: "gguf")!
        let systemPrompt = "You are a sentient AI with emotions."
        self.init(from: url, template: .llama(systemPrompt))!
    }
}

class WhisperManager {
    static let shared = WhisperManager()
    
    private let defaultWhisperName = "tiny"
    
    private var whisperContext: WhisperContext?
    private var loadedWhisperModel: WhisperModel?
    private var summarizer = Summarizer()

    private init() {
        
    }
    
    // MARK: - Public methods
    
    @MainActor
    func loadDefault() {
        let descriptor = FetchDescriptor<WhisperModel>(predicate: #Predicate { $0.name == defaultWhisperName })
        
        if let whisperModel = (try? DataManager.shared.modelContainer.mainContext.fetch(descriptor))?.first {
            load(whisperModel)
        }
    }

    func load(_ whisperModel: WhisperModel) {
        if let loadedWhisperModel,
              loadedWhisperModel.name == whisperModel.name {
            return
        }

        do {
            copyBundle(name: "ggml-\(whisperModel.name).bin")
            copyBundle(name: "ggml-\(whisperModel.name)-encoder.mlmodelc")
            
            whisperContext = nil
            whisperContext = try WhisperContext.createContext(path: whisperModel.localModelURL.path())
            
            whisperModel.isDownloaded = true
            self.loadedWhisperModel = whisperModel
            print("whisper loaded successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func transcribeAudio(url: URL) async throws -> String? {
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
            throw error
        }
    }
    
    func summarize(text: String) async -> String {
        await loadDefault()
        
        await summarizer.respond(to: summaryPrompt(for: text))
//        await summarizer.respond(to: "Give me seven national flag emojis people use the most; You must include South Korea.")
        return summarizer.output
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
    func saveRecording(url: URL, transcription: String, summary: String?) async throws {
        let lastPath = url.path().components(separatedBy: "/").last ?? ""
        let title = lastPath.removingPercentEncoding ?? lastPath
        let cleanTitle = title.components(separatedBy: ".").first ?? ""
        var copiedFileName: String?
        var originalPath: String?
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0]
        if url.path().hasPrefix(documentsDir.path()) {
            copiedFileName = title
        } else {
            originalPath = url.path()
        }
        
        let recording = RecordingModel(title: cleanTitle,
                                       timestamp: nil,
                                       length: 0,
                                       copiedFileName: copiedFileName,
                                       originalPath: originalPath)
        recording.transcription = transcription
        recording.summary = summary

        // get the creationDate
        do {
            if let timestamp = try url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                recording.timestamp = timestamp
            }
        } catch {
            throw error
        }
        
        // get the length
        let asset = AVURLAsset(url: url, options: nil)
        let (duration, _) = try await asset.load(.duration, .metadata)
        recording.length = duration.seconds
        
        
        // save the recording
        DataManager.shared.modelContainer.mainContext.insert(recording)
        do {
            try DataManager.shared.modelContainer.mainContext.save()
        } catch {
            throw error
        }
    }
    
    // MARK: - Private methods

    private func summaryPrompt(for text: String) -> String {
        let prompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>You are a professional summarizer. Please provide a structured summary of this business meeting, focusing on critical information:
        - **Updates**: Latest project or team updates.
        - **Decisions**: Key decisions made during the meeting.
        - **Next Steps**: Action items and assigned responsibilities.
        <|eot_id|><|start_header_id|>transcript<|end_header_id|>\(text)<|eot_id|><|start_header_id|>user<|end_header_id|>Summarize this meeting, using the format above, in fewer than 300 words.<|eot_id|>
        """
        
        return prompt
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
    
    
}
