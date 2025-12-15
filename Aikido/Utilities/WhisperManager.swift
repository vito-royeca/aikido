//
//  WhisperManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation
import AudioKit
import AVFoundation
import SwiftData
import SwiftUI

import LLM
import SwiftWhisper

class Summarizer: LLM {
    convenience init() {
        let url = Bundle.main.url(forResource: "tinyllama-1.1b-chat-v1.0.Q2_K", withExtension: "gguf")!
        let systemPrompt = "You are a sentient AI with emotions."
        self.init(from: url, template: .llama(systemPrompt))!
    }
}

class WhisperManager {
    static let shared = WhisperManager()
    
    @AppStorage(.settingsWhisperNameKey)
    private var defaultWhisperName = "tiny"
    
    private var loadedWhisperModel: WhisperModel?
    private var summarizer = Summarizer()
//    private var segments = [Segment]()
    private var whisper: Whisper?
    private var currentSegmentStartTime = 0
    
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
        guard whisperModel.name != loadedWhisperModel?.name else {
            return
        }

        copyBundle(name: "ggml-\(whisperModel.name).bin")
        copyBundle(name: "ggml-\(whisperModel.name)-encoder.mlmodelc")
        
        whisperModel.isDownloaded = true
        self.loadedWhisperModel = whisperModel
        whisper = Whisper(fromFileURL: whisperModel.localModelURL)
        print("\(whisperModel.name) - Whisper model loaded successfully")
    }
    
    func transcribeAudio(url: URL) async throws -> [Segment] {
        do {
            let data = try await readAudioSamples(url)
            return try await transcribe(data: data)
        } catch {
            throw error
        }
    }
    
    func transcribe(data: [Float]) async throws -> [Segment] {
        await loadDefault()

        guard let whisper else {
            return []
        }
        
        do {
            let segments = try await whisper.transcribe(audioFrames: data)
            return segments
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

    private func readAudioSamples(_ url: URL) async throws -> [Float] {
        try await withCheckedThrowingContinuation { continuation in
            convertAudioFileToPCMArray(fileURL: url) { result in
                switch result {
                case .success(let floats):
                    continuation.resume(returning: floats)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func convertAudioFileToPCMArray(fileURL: URL, completionHandler: @escaping (Result<[Float], Error>) -> Void) {
        var options = FormatConverter.Options()
        options.format = .wav
        options.sampleRate = 16000
        options.bitDepth = 16
        options.channels = 1
        options.isInterleaved = false

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let converter = FormatConverter(inputURL: fileURL, outputURL: tempURL, options: options)
        converter.start { error in
            if let error {
                completionHandler(.failure(error))
                return
            }

            let data = try! Data(contentsOf: tempURL) // Handle error here

            let floats = stride(from: 44, to: data.count, by: 2).map {
                return data[$0..<$0 + 2].withUnsafeBytes {
                    let short = Int16(littleEndian: $0.load(as: Int16.self))
                    return max(-1.0, min(Float(short) / 32767.0, 1.0))
                }
            }

            try? FileManager.default.removeItem(at: tempURL)

            completionHandler(.success(floats))
        }
    }
}

//extension WhisperManager: WhisperDelegate {
//    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
//        
//    }
//
//    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
//        
//    }
//  
//    func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
//        
//    }
//
//    func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
//        
//    }
//}

