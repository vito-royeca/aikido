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
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: RecorderViewModel
    var recording: RecordingModel

    @State private var selectedTab: RecordingTab = .transcription

    var body: some View {
        contentView
            .toolbar {
                RecordingDetailsToolbar(deleteAction: deleteRecording)
            }
    }
    
    var contentView: some View {
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
                    Text(recording.transcriptionWithTime ?? "")
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
    
    func deleteRecording() {
        if let copiedFileURL = recording.copiedFileURL {
            viewModel.deleteRecording(url: copiedFileURL)
        }
        modelContext.delete(recording)
        do {
            try DataManager.shared.modelContainer.mainContext.save()
        } catch {
            print(error)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct RecordingDetailsToolbar: ToolbarContent {
    var deleteAction: () -> Void
    @State private var isPresentingDelete = false
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                isPresentingDelete = true
            }, label: {
                Image(systemName: "trash")
            })
            .confirmationDialog("Delete this Recording?",
                                isPresented: $isPresentingDelete,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteAction()
                }
            } message: {
                Text("You cannot undo this action.")
            }
        }
    }
}

#Preview {
    let recording = RecordingModel(title: "Test.wav",
                                   timestamp: Date(),
                                   length: 100,
                                   copiedFileName: "file.wav",
                                   originalPath: "/path/file.wav")

    RecordingDetailsView(recording: recording)
}
