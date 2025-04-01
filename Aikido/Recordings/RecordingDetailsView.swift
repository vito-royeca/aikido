//
//  RecordingDetailsView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/30/25.
//

import SwiftUI

struct RecordingDetailsView: View {
    var recording: Recording

    var body: some View {
        VStack {
            PlayerView(title: recording.title,
                       audioURL: recording.copiedFileURL ?? recording.originalPathURL ?? nil)

            ScrollView {
                Text(recording.transcription ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
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
