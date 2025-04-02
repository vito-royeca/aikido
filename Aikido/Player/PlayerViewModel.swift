//
//  PlayerViewModel.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import SwiftUI
import AVFoundation
import Accelerate

enum PlayerConstants {
    static let updateInterval = 0.03
    static let barAmount = 40
    static let magnitudeLimit: Float = 32
}

class PlayerViewModel: NSObject, ObservableObject {
    
    // MARK: - Public properties

    var isPlaying = false {
        willSet {
            withAnimation {
                objectWillChange.send()
            }
        }
    }

    var isPlayerReady = false {
        willSet {
            objectWillChange.send()
        }
    }

    var playerProgress: Double = 0 {
        willSet {
            objectWillChange.send()
        }
    }

    var playerTime: PlayerDisplay = .zero {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var data: [Float] = Array(repeating: 0,
                                         count: PlayerConstants.barAmount)

    // MARK: - Private properties

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timeEffect = AVAudioUnitTimePitch()
    private let timeToSeek = Double(10)
    private let bufferSize = 1024

    private var displayLink: CADisplayLink?

    private var needsFileScheduled = true

    private var audioFile: AVAudioFile?
    private var audioSampleRate: Double = 0
    private var audioLengthSeconds: Double = 0

    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0

    private var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
            return 0
        }

        return playerTime.sampleTime
    }

    private var fftMagnitudes: [Float] = []

    // MARK: - Public

    override init() {
        super.init()
        setupDisplayLink()
    }

    func playOrPause() {
        isPlaying.toggle()

        if player.isPlaying {
            displayLink?.isPaused = true
            disconnectVisualizerTap()
            player.pause()
        } else {
            displayLink?.isPaused = false
            connectVisualizerTap()

            if needsFileScheduled {
                scheduleAudioFile()
            }
            player.play()
        }
    }

    func stop() {
        isPlaying = false
        displayLink?.isPaused = true
        disconnectVisualizerTap()
        player.stop()
    }

    func skip(forwards: Bool) {
        let time: Double

        if forwards {
            time = timeToSeek
        } else {
            time = -timeToSeek
        }

        seek(to: time)
    }

    func setupWithAudio(url: URL) {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat

            audioLengthSamples = file.length
            audioSampleRate = format.sampleRate
            audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate

            audioFile = file

            configureEngine(with: format)
        } catch {
            print("Error reading the audio file: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func configureEngine(with format: AVAudioFormat) {
        engine.attach(player)
        engine.attach(timeEffect)

        engine.connect(player,
                       to: timeEffect,
                       format: format)
        
        engine.connect(timeEffect,
                       to: engine.mainMixerNode,
                       format: format)

        engine.prepare()

        do {
            try engine.start()

            scheduleAudioFile()
            isPlayerReady = true
        } catch {
            print("Error starting the player: \(error.localizedDescription)")
        }
    }

    private func scheduleAudioFile() {
        guard let file = audioFile,
            needsFileScheduled else {
            return
        }

        needsFileScheduled = false
        seekFrame = 0

        player.scheduleFile(file, at: nil) {
            self.needsFileScheduled = true
        }
    }

    // MARK: - Audio adjustments

    private func seek(to time: Double) {
        guard let audioFile else {
            return
        }

        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offset
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame

        let wasPlaying = player.isPlaying
        player.stop()

        if currentPosition < audioLengthSamples {
            updateDisplay()
            needsFileScheduled = false

            let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)
            player.scheduleSegment(audioFile,
                                   startingFrame: seekFrame,
                                   frameCount: frameCount,
                                   at: nil) {
                self.needsFileScheduled = true
            }

            if wasPlaying {
                player.play()
            }
        }
    }

    private func connectVisualizerTap() {
        let fftSetup = vDSP_DFT_zop_CreateSetup(nil,
                                                UInt(bufferSize),
                                                vDSP_DFT_Direction.FORWARD)
            
        engine.mainMixerNode.installTap(onBus: 0,
                                        bufferSize: UInt32(bufferSize),
                                        format: nil) { [self] buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
        }
    }
    
    private func disconnectVisualizerTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
    }

    // MARK: - Display updates

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(updateDisplay))
        displayLink?.add(to: .current, forMode: .default)
        displayLink?.isPaused = true
    }

    @objc private func updateDisplay() {
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)

        if currentPosition >= audioLengthSamples {
            player.stop()

            seekFrame = 0
            currentPosition = 0

            isPlaying = false
            displayLink?.isPaused = true

            disconnectVisualizerTap()
        }

        playerProgress = Double(currentPosition) / Double(audioLengthSamples)

        let time = Double(currentPosition) / audioSampleRate
        playerTime = PlayerDisplay(elapsedTime: time,
                                   remainingTime: audioLengthSeconds - time)
        
        if isPlaying {
            withAnimation(.easeOut(duration: 0.08)) {
                data = fftMagnitudes.map {
                    min($0, PlayerConstants.magnitudeLimit)
                }
            }
        }
    }
}

extension PlayerViewModel {
    func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: bufferSize)
        var imagIn = [Float](repeating: 0, count: bufferSize)
        var realOut = [Float](repeating: 0, count: bufferSize)
        var imagOut = [Float](repeating: 0, count: bufferSize)
            
        for i in 0 ..< bufferSize {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: PlayerConstants.barAmount)
        
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(PlayerConstants.barAmount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: PlayerConstants.barAmount)
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(PlayerConstants.barAmount))
            
        return normalizedMagnitudes
    }
}
