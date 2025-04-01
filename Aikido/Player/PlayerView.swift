//
//  PlayerView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import Charts
import SwiftUI

struct PlayerView: View {
    var title: String?
    var audioURL: URL?

    @StateObject var viewModel = PlayerViewModel()
    
    private let timer = Timer.publish(every: PlayerConstants.updateInterval,
                                      on: .main,
                                      in: .common)
        .autoconnect()

    var body: some View {
        VStack {
            if let title {
                Text(title)
                    .font(.footnote)
            }
            chartView
            controlsView
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding()
        .onAppear {
            if let audioURL {
                viewModel.setupWithAudio(url: audioURL)
            }
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    var chartView: some View {
        Chart(Array(viewModel.data.enumerated()), id: \.0) { index, magnitude in
            BarMark(
                x: .value("Frequency", String(index)),
                y: .value("Magnitude", magnitude)
            )
            .foregroundStyle(
                Color(
                    hue: 0.3 - Double((magnitude / PlayerConstants.magnitudeLimit) / 5),
                    saturation: 1,
                    brightness: 1,
                    opacity: 0.7
                )
            )
        }
        .onReceive(timer, perform: viewModel.updateData)
        .chartYScale(domain: 0 ... PlayerConstants.magnitudeLimit)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 50)
        .padding()
        .background(
            .black
                .opacity(0.3)
                .shadow(.inner(radius: 20))
        )
        .cornerRadius(10)
    }
    
    var controlsView: some View {
        VStack {
            HStack {
                Text(viewModel.playerTime.elapsedText)

                ProgressView(value: viewModel.playerProgress)
                    .tint(.secondary)
                    .padding(.vertical)

                Text(viewModel.playerTime.remainingText)
            }
            .font(.footnote)
            
            HStack(spacing: 40) {
                Button(action: {
                    viewModel.skip(forwards: false)
                }, label: {
                    Image(systemName: "10.arrow.trianglehead.counterclockwise")
                })
                
                Button(action: {
                    viewModel.playOrPause()
                }, label: {
                    Image(systemName: "\(viewModel.isPlaying ? "pause" : "play").circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                })
                
                Button(action: {
                    viewModel.skip(forwards: true)
                }, label: {
                    Image(systemName: "10.arrow.trianglehead.clockwise")
                })
            }
            .padding(10)
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PlayerView(title: "Title",
               audioURL: Bundle.main.url(forResource: "jfk", withExtension: "wav"))
}
