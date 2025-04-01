//
//  RecorderViewModel.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import AVFoundation

class RecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedURL: URL?

    private let fileExtension = "wav"
    private let settings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
//        AVEncoderBitRateKey: 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 12000.0
    ] as [String: Any]
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    private var audioFileName: URL?
    
    func start() {
        audioSession = AVAudioSession.sharedInstance()
        recordedURL = nil

        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default,
                                          options: [.defaultToSpeaker,.mixWithOthers])
            try audioSession?.setActive(true)

            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.isRecording = true
                    } else {
                        self.isRecording = false
                        print("Error: permission not granted")
                    }
                }
            }
        } catch {
            print("Failed to record")
            audioSession = nil
            return
        }
        
        let fileName = "New Recording " + String(getNextID()) + "." + fileExtension
        audioFileName = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0].appendingPathComponent(fileName)
 
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        }  catch {
            audioRecorder = nil
            print("AVAudioRecorder error: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioRecorder?.stop()
    }
}

// MARK: - Helper

extension RecorderViewModel {
    func getNextID(_ reset: Bool = false) -> Int {
        var nextID = UserDefaults.standard.integer(forKey: "aikido.record.nextID")

        if reset {
            nextID = 1
        } else {
            nextID += 1
            UserDefaults.standard.setValue(nextID, forKey: "aikido.record.nextID")
        }
        return nextID
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecorderViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        if flag {
            audioRecorder?.stop()
            audioRecorder = nil
            recordedURL = audioFileName
            isRecording = false
            print("New audiofile: ", audioFileName?.lastPathComponent ?? "")
        } else {
            print("finishRecording: failed recording")
        }
    }
}
