//
//  RecordingDetailsView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/30/25.
//

import SwiftUI

enum RecordingTab: String, CaseIterable, Identifiable {
    case transcription
    case summary
    
    var id: Self {
        self
    }
}

struct RecordingDetailsView: View {
    var recording: Recording

    @State private var selectedTab: RecordingTab = .transcription

    var body: some View {
        VStack {
            PlayerView(title: recording.title,
                       audioURL: recording.copiedFileURL ?? recording.originalPathURL ?? nil)

            Picker("", selection: $selectedTab) {
                ForEach(RecordingTab.allCases) { tab in
                    Text(tab.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTab) {
                if selectedTab == .summary {
                    summarize()
                }
            }
            
            ScrollView {
                switch selectedTab {
                case .transcription:
                    Text(recording.transcription ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .summary:
                    Text(recording.summary ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }
    
    func summarize() {
        Task {
            if let transcription = recording.transcription {
                recording.summary = await WhisperManager.shared.summarize(text: transcription)
            }
                
        }
    }
}

#Preview {
    let recording = Recording(title: "Test.wav",
                              timestamp: Date(),
                              length: 100,
                              copiedFileName: "file.wav",
                              originalPath: "/path/file.wav")

    RecordingDetailsView(recording: recording)
}
