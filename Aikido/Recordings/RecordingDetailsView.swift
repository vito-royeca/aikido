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
    @Environment(\.contentViewState) private var contentViewState
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
                contentViewState.isShowingRecordButton = false
            }
            .onDisappear {
                contentViewState.isShowingRecordButton = true
            }
            .navigationTitle(recording.title)
    }
    
    var contentView: some View {
        VStack {
            infoView
                .padding(.leading)
                .padding(.trailing)

            switch selectedTab {
            case .transcription:
                transcriptionView
            case .summary:
                summaryView
            }
        }
    }
    
    var infoView: some View {
        VStack {
            HStack {
                Text(recording.formattedTimestamp)
                    .font(.footnote)
                Spacer()
                Text(recording.placeName ?? "")
                    .font(.footnote)
            }
            PlayerView(title: recording.title,
                       audioURL: recording.copiedFileURL ?? recording.originalPathURL ?? nil)
            
            Picker("", selection: $selectedTab) {
                ForEach(RecordingTab.allCases) { tab in
                    Text(tab.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var transcriptionView: some View {
        ScrollView {
            Text(recording.transcriptionWithTime ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }

    var summaryView: some View {
        ScrollView {
            Text(recording.summary ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .refreshable {
            isGeneratingSummary = true
            summarize()
        }
    }
    
    func summarize() {
        if let transcription = recording.transcription,
           let bot = contentViewState.bot {
            Task {
                do {
                    recording.summary = await bot.summarize(text: transcription)
                    try DataManager.shared.modelContainer.mainContext.save()
                    await MainActor.run {
                        isGeneratingSummary = false
                    }
                } catch {
                    await MainActor.run {
                        isGeneratingSummary = false
                    }
                    print(error)
                }
            }
        } else {
            isGeneratingSummary = false
        }
    }
    
    func deleteRecording() {
        do {
            if let copiedFileURL = recording.copiedFileURL {
                viewModel.deleteRecording(url: copiedFileURL)
            }
            modelContext.delete(recording)
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
            Button {
                isPresentingDelete = true
            } label: {
                Image(systemName: "trash")
            }
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
                                   latitude: 0,
                                   longitude: 0,
                                   placeName: nil,
                                   length: 100,
                                   copiedFileName: "file.wav",
                                   originalPath: "/path/file.wav")

    RecordingDetailsView(recording: recording)
}

