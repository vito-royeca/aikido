//
//  TranscriberView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/30/25.
//

import SwiftUI

struct TranscriberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var url: URL?

    @State private var transcription: String = "Transcribing..."

    var body: some View {
        NavigationStack {
            contentView
                .toolbar {
                    TranscriberToolbar(cancelAction: deleteRecording,
                                       saveAction: saveRecording)
                }
                .onAppear {
                    transcribeAudio()
                }
        }
    }
    
    var contentView: some View {
        VStack {
            if let url {
                Text(url.lastPathComponent)
            }

            ScrollView {
                Text(transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private func transcribeAudio() {
        guard let url else {
            return
        }

        Task {
            let text = await WhisperManager.shared.transcribeAudio(url: url)
            transcription = text ?? ""
        }
    }
    
    private func deleteRecording() {
        if let url {
            WhisperManager.shared.deleteRecording(url: url)
        }
        dismiss()
    }

    private func saveRecording() {
        if let url {
            WhisperManager.shared.saveRecording(url: url, transcription: transcription)
        }
        dismiss()
    }
}

#Preview {
    TranscriberView()
}

struct TranscriberToolbar: ToolbarContent {
    var cancelAction: () -> Void
    var saveAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                cancelAction()
            }, label: {
                Text("Cancel")
            })
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                saveAction()
            }, label: {
                Text("Save")
            })
        }
    }
}
