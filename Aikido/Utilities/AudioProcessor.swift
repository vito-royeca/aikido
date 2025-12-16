//
//  AudioProcessor.swift
//  Aikido
//
//  Created by Vito Royeca on 12/14/25.
//

import AVFoundation
import SwiftWhisper

protocol AudioProcessorDelegate {
    func handle(newSegments: [Segment])
}

class AudioProcessor: NSObject {
    var delegate: AudioProcessorDelegate?
    var audioFileName: URL?
    
    // MARK: - Recorder variables

    private let fileExtension = "wav"
    private let fileSettings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
//        AVEncoderBitRateKey: 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 12000.0
    ] as [String: Any]
    private var audioRecorder: AVAudioRecorder?

    // MARK: - Capture variables
    
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    
    /// Whisper expects 16 kHz audio.
    private let targetSampleRate: Double = 16_000
    
    /// Analysis window size in seconds for each inference.
    private let windowSeconds: Double = 3.0
    
    /// Minimum interval in seconds between consecutive inferences (hop size).
    private let hopSeconds: Double = 1.0
    
    /// Minimum seconds of audio required before allowing the first inference.
    private let minFirstTriggerSeconds: Double = 2.0
    
    /// Level gate: minimum decibels full scale required for inference.
    /// Lower (e.g., -65 dBFS) is more permissive for quiet inputs.
    private let minDecibelsFullScaleToTranscribe: Double = -45.0
    
    /// Accumulated audio frames (Float32, mono, 16 kHz).
    private var accumulatedFrames: [Float] = []
    
    /// Prevents overlapping inferences.
    private var isRunningInference: Bool = false
    
    /// Debounce control for the sliding window.
    private var lastInferenceTime: TimeInterval = 0
    
    /// Indicates that at least one inference has already been performed.
    private var hasTriggeredOnce: Bool = false
    
    @discardableResult
    func configureAudioSession() -> Bool {
        let session: AVAudioSession = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord,
                                    mode: .voiceChat,
                                    options: [.duckOthers,
                                              .defaultToSpeaker,
                                              AVAudioSession.CategoryOptions.allowBluetoothHFP])
        } catch {
            // Keep going; conversion path still works even if category fallback occurs.
        }

        do {
            try session.setPreferredSampleRate(targetSampleRate)
        } catch {
            // If not honored, software resampling will occur.
        }

        do {
            try session.setPreferredIOBufferDuration(0.01)
        } catch {
            // Fall back to system default buffer duration.
        }

        do {
            try session.setActive(true,
                                  options: .notifyOthersOnDeactivation)
        } catch {
            return false
        }

        do {
            try session.setPreferredInputNumberOfChannels(1)
        } catch {
            // If the device keeps stereo input, software downmix will occur.
        }

        return true
    }
    
    func start() -> Bool {
        guard configureCapture(),
              configureRecorder() else {
            return false
        }

        do {
            try audioEngine.start()
            return true
        } catch {
            // If the engine fails to start, recording does not begin.
            return false
        }
    }
    
    /// Stops audio capture, removes the input tap, and clears buffers.
    func stop() {
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        accumulatedFrames.removeAll(keepingCapacity: false)
        isRunningInference = false
        hasTriggeredOnce = false
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false,
                                                       options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Utilityy methods
    private func configureCapture() -> Bool {
        let input: AVAudioInputNode = audioEngine.inputNode
        inputNode = input

        let inputFormat: AVAudioFormat = input.outputFormat(forBus: 0)
        let inputSampleRate: Double = inputFormat.sampleRate
        let inputChannels: Int = Int(inputFormat.channelCount)

        let tapBufferSize: AVAudioFrameCount = 8_192
        let windowFrameCount: Int = Int(windowSeconds * targetSampleRate)

        // Reset state
        accumulatedFrames.removeAll(keepingCapacity: true)
        isRunningInference = false
        lastInferenceTime = 0
        hasTriggeredOnce = false

        // Determine whether the input is already in Whisper’s required format.
        let isAlreadyTargetFormat: Bool =
        abs(inputSampleRate - targetSampleRate) < 0.5 &&
        inputChannels == 1 &&
        inputFormat.commonFormat == .pcmFormatFloat32

        if isAlreadyTargetFormat {
            // Fast path: directly append Float32 frames.
            input.installTap(onBus: 0,
                             bufferSize: tapBufferSize,
                             format: inputFormat) { [weak self] inputBuffer, _ in
                guard let strongSelf = self else { return }

                let frameCount: Int = Int(inputBuffer.frameLength)
                guard frameCount > 0 else { return }
                guard let floatChannelPointer = inputBuffer.floatChannelData?[0] else { return }

                let buffer = UnsafeBufferPointer(start: floatChannelPointer,
                                                 count: frameCount)
                strongSelf.accumulatedFrames.append(contentsOf: buffer)

                // Keep up to 2× window frames to limit memory growth.
                if strongSelf.accumulatedFrames.count > windowFrameCount * 2 {
                    let toRemove: Int = strongSelf.accumulatedFrames.count - windowFrameCount * 2
                    strongSelf.accumulatedFrames.removeFirst(toRemove)
                }

                strongSelf.maybeTriggerInference(windowFrameCount: windowFrameCount,
                                                 contextTag: "fast-path")
            }
        } else {
            // Convert path: downmix to mono (device SR) then resample to 16 kHz Float32.
            guard let downmixMonoFormat: AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                                       sampleRate: inputSampleRate,
                                                                       channels: 1,
                                                                       interleaved: false),
                let whisperOutputFormat: AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                                       sampleRate: targetSampleRate,
                                                                       channels: 1,
                                                                       interleaved: false),
                let downmixConverter: AVAudioConverter = AVAudioConverter(from: inputFormat,
                                                                          to: downmixMonoFormat),
                let resampleConverter: AVAudioConverter = AVAudioConverter(from: downmixMonoFormat,
                                                                           to: whisperOutputFormat) else {
                return false
            }

            let sampleRateRatio: Double = targetSampleRate / inputSampleRate

            input.installTap(onBus: 0,
                             bufferSize: tapBufferSize,
                             format: inputFormat) { [weak self] inputBuffer, _ in
                guard let strongSelf = self else { return }

                let inputFrameCount: Int = Int(inputBuffer.frameLength)
                guard inputFrameCount > 0 else { return }

                // Stage 1: downmix to mono at device sample rate
                guard let intermediateMonoBuffer = AVAudioPCMBuffer(pcmFormat: downmixMonoFormat,
                                                                    frameCapacity: AVAudioFrameCount(inputFrameCount)) else {
                    return
                }

                var downmixError: NSError?
                var suppliedInputOnce: Bool = false
                _ = downmixConverter.convert(to: intermediateMonoBuffer,
                                             error: &downmixError) { _, outStatus in
                    if suppliedInputOnce || inputBuffer.frameLength == 0 {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    suppliedInputOnce = true
                    outStatus.pointee = .haveData
                    return inputBuffer
                }
                if downmixError != nil { return }

                let intermediateFrames: Int = Int(intermediateMonoBuffer.frameLength)
                guard intermediateFrames > 0 else { return }

                // Stage 2: resample mono to 16 kHz Float32
                let estimatedOutputFrames: Int = Int(
                    ceil(Double(intermediateFrames) * sampleRateRatio)
                )
                let capacityFrames: Int = max(intermediateFrames, estimatedOutputFrames)

                guard let whisperInputBuffer = AVAudioPCMBuffer(pcmFormat: whisperOutputFormat,
                                                                frameCapacity: AVAudioFrameCount(capacityFrames)) else {
                    return
                }

                var resampleError: NSError?
                var suppliedMonoOnce: Bool = false
                _ = resampleConverter.convert(to: whisperInputBuffer,
                                              error: &resampleError) { _, outStatus in
                    if suppliedMonoOnce || intermediateMonoBuffer.frameLength == 0 {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    suppliedMonoOnce = true
                    outStatus.pointee = .haveData
                    return intermediateMonoBuffer
                }
                if resampleError != nil { return }

                let producedFrameCount: Int = Int(whisperInputBuffer.frameLength)
                guard producedFrameCount > 0 else { return }
                guard let floatChannelPointer = whisperInputBuffer.floatChannelData?[0] else { return }

                let buffer = UnsafeBufferPointer(start: floatChannelPointer,
                                                 count: producedFrameCount)
                strongSelf.accumulatedFrames.append(contentsOf: buffer)

                // Keep up to 2× window frames to limit memory growth.
                if strongSelf.accumulatedFrames.count > windowFrameCount * 2 {
                    let toRemove: Int = strongSelf.accumulatedFrames.count - windowFrameCount * 2
                    strongSelf.accumulatedFrames.removeFirst(toRemove)
                }

                strongSelf.maybeTriggerInference(windowFrameCount: windowFrameCount,
                                                 contextTag: "convert-path")
            }
        }
        
        return true
    }
    
    private func configureRecorder() -> Bool {
        let fileName = "New Recording " + String(getNextID()) + "." + fileExtension
        audioFileName = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0].appendingPathComponent(fileName)
 
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName!, settings: fileSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            return true
        }  catch {
            audioRecorder = nil
            print("AVAudioRecorder error: \(error.localizedDescription)")
            return false
        }
    }
    
    private func getNextID(_ reset: Bool = false) -> Int {
        var nextID = UserDefaults.standard.integer(forKey: "aikido.record.nextID")

        if reset {
            nextID = 1
        } else {
            nextID += 1
            UserDefaults.standard.setValue(nextID, forKey: "aikido.record.nextID")
        }
        return nextID
    }

    /// Evaluates whether an inference should be triggered based on window size,
    /// debounce interval, and audio level threshold. If conditions are satisfied,
    /// this method performs an asynchronous transcription using Whisper and appends
    /// any non-empty text to `transcription`.
    ///
    /// - Parameters:
    ///   - windowFrameCount: Number of frames in the analysis window.
    ///   - contextTag: A contextual string to help identify the code path
    ///                 (e.g., `"fast-path"` or `"convert-path"`). Not logged.
    private func maybeTriggerInference(windowFrameCount: Int,
                                       contextTag: String) {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        let minFramesForFirst: Int = Int(minFirstTriggerSeconds * targetSampleRate)
        let hasFullWindow: Bool = accumulatedFrames.count >= windowFrameCount
        let hasEnoughForFirst: Bool = accumulatedFrames.count >= minFramesForFirst || hasTriggeredOnce
        let isDebouncedNow: Bool = (currentTime - lastInferenceTime) >= hopSeconds
        let canTrigger: Bool = (!isRunningInference && hasEnoughForFirst && isDebouncedNow)

        guard canTrigger else { return }

        // Slice either a full window or the minimal first window.
        let desiredCount: Int = hasFullWindow
            ? windowFrameCount
            : max(accumulatedFrames.count, minFramesForFirst)

        let startIndex: Int = max(0, accumulatedFrames.count - desiredCount)
        let framesForInference: [Float] = Array(accumulatedFrames[startIndex..<accumulatedFrames.count])

        // Gate by measured audio level to avoid wasting compute on silence.
        let (_, decibelsFullScale) = Self.audioLevelMetrics(for: framesForInference)
        guard decibelsFullScale >= minDecibelsFullScaleToTranscribe else { return }

        lastInferenceTime = currentTime
        isRunningInference = true

        let framesCopy: [Float] = framesForInference

        Task.detached { [weak self, framesCopy] in
            guard let strongSelf = self else { return }

            do {
                let segments: [Segment] = try await WhisperManager.shared.transcribe(data: framesCopy)
                let text = segments
                        .map(\.text)
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    strongSelf.delegate?.handle(newSegments: segments)
                    if !text.isEmpty {
                        strongSelf.hasTriggeredOnce = true
                    }
                    strongSelf.isRunningInference = false
                }
            } catch {
                await MainActor.run {
                    strongSelf.isRunningInference = false
                }
            }
        }
    }
    
    /// Computes simple audio level metrics.
    ///
    /// - Note: This uses a partial sampling to keep cost low for large buffers.
    /// - Parameter frames: Float32 PCM mono samples in the range `[-1, 1]`.
    /// - Returns: A tuple `(rootMeanSquare, decibelsFullScale)`. The dBFS reference is full scale = 1.0.
    private static func audioLevelMetrics(for frames: [Float]) -> (Double, Double) {
        guard !frames.isEmpty else { return (0.0, -120.0) }

        var sumSquares: Double = 0
        let step: Int = max(1, frames.count / 8_000)
        var count: Int = 0
        var index: Int = 0

        while index < frames.count {
            let sample: Double = Double(frames[index])
            sumSquares += sample * sample
            count += 1
            index += step
        }

        guard count > 0 else { return (0.0, -120.0) }

        let rootMeanSquare: Double = sqrt(sumSquares / Double(count))
        let decibelsFullScale: Double = 20.0 * log10(max(rootMeanSquare, 1e-8))
        return (rootMeanSquare, decibelsFullScale)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioProcessor: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        if flag {
            audioRecorder?.stop()
            audioRecorder = nil
            print("Saved: ", audioFileName?.lastPathComponent ?? "")
        } else {
            print("Failed recording")
        }
    }
}
