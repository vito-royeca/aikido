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
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.contentViewState) private var conrentViewState
    @EnvironmentObject private var viewModel: RecorderViewModel
    var recording: RecordingModel

    @State private var selectedTab: RecordingTab = .transcription
    @State private var isGeneratingSummary = false

    var body: some View {
        contentView
            .toolbar {
                RecordingDetailsToolbar(deleteAction: deleteRecording)
            }
            .onAppear {
                conrentViewState.isShowingRecordButton = false
            }
            .onDisappear {
                conrentViewState.isShowingRecordButton = true
            }
    }
    
    var contentView: some View {
        VStack {
            VStack {
                PlayerView(title: recording.title,
                           audioURL: recording.copiedFileURL ?? recording.originalPathURL ?? nil)
                
                Picker("", selection: $selectedTab) {
                    ForEach(RecordingTab.allCases) { tab in
                        Text(tab.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            switch selectedTab {
            case .transcription:
                ScrollView {
                    Text(recording.transcriptionWithTime ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .summary:
                ScrollView {
                    Text(recording.summary ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .refreshable {
                    isGeneratingSummary = true
                    summarize()
                }
            }
        }
    }
    
    func summarize() {
        Task {
            if let transcription = recording.transcription {
                recording.summary = await WhisperManager.shared.summarize(text: transcription)
                do {
                    try DataManager.shared.modelContainer.mainContext.save()
                } catch {
                    print(error)
                }
            }

            await MainActor.run {
                isGeneratingSummary = false
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
