//
//  RecorderViewModel.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import AVFoundation
import SwiftWhisper

class RecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isSaving = false
    @Published var segments = [SegmentModel]()
    
    var bot: AIBot? = nil
    var locationManager: LocationManager? = nil
    
    private var audioProcessor = AudioProcessor()

    // MARK: - Public methods

    func start() {
        guard audioProcessor.configureAudioSession() else {
            return
        }

        audioProcessor.delegate = self
        isRecording = audioProcessor.start()
        segments = []
    }

    func stop() {
        audioProcessor.stop()
        audioProcessor.delegate = nil
        isRecording = false
        
        // save
        guard let url = audioProcessor.audioFileName else { return }
        Task {
            do {
//                try await saveRecording(url: url, segments: segments)
                try await importAudio(from: url)
            } catch {
                await MainActor.run {
                    isSaving = false
                }
                print(error)
            }
        }
    }

    
    @MainActor
    func importAudio(from url: URL) async throws {
        await MainActor.run {
            isSaving = true
        }
        
        let segments = try await WhisperManager.shared.transcribeAudio(url: url)
        let models = segments.map { SegmentModel(startTime: $0.startTime, endTime: $0.endTime, text: $0.text) }
        try await saveRecording(url: url, segments: models)

        await MainActor.run {
            isSaving = false
        }
    }

    @MainActor
    func saveRecording(url: URL, segments: [SegmentModel]) async throws {
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
                                       latitude: locationManager?.coordinate?.latitude ?? 0,
                                       longitude: locationManager?.coordinate?.longitude ?? 0,
                                       placeName: locationManager?.placeName,
                                       length: 0,
                                       copiedFileName: copiedFileName,
                                       originalPath: originalPath)
        recording.segments = segments
        recording.generateTranscriptions()
        
        if let transcription = recording.transcription,
           let bot {
            let summary = await bot.summarize(text: transcription)
            recording.summary = summary
        }

//        // get the original creationDate
//        do {
//            if let timestamp = try url.resourceValues(forKeys: [.creationDateKey]).creationDate {
//                recording.timestamp = timestamp
//            }
//        } catch {
//            throw error
//        }

        // set the creationDate to Now
        recording.timestamp = Date()
        
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

    var newTitle: String {
        get {
            guard let url = audioProcessor.audioFileName else { return "New Recording" }
            let lastPath = url.path().components(separatedBy: "/").last ?? ""
            let title = lastPath.removingPercentEncoding ?? lastPath
            let cleanTitle = title.components(separatedBy: ".").first ?? ""
            return cleanTitle
        }
    }
}

// MARK: - AudioCaptureDelegate

extension RecorderViewModel: AudioProcessorDelegate {
    func handle(newSegments: [Segment]) {
        let array = newSegments.map { SegmentModel(startTime: $0.startTime, endTime: $0.endTime, text: $0.text) }
        segments.append(contentsOf: array)
    }
}

