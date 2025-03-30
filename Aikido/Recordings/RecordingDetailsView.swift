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
        NavigationStack {
            ScrollView {
                Text(recording.transcription ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .navigationTitle(recording.title)
        }
    }
}

#Preview {
    let recording = Recording(title: "Test.wav",
                              timestamp: Date(),
                              length: 100,
                              audioPath: "/path/file.wav")
    
    RecordingDetailsView(recording: recording)
}
