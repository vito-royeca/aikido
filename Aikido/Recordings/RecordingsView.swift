//
//  RecordingsView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/29/25.
//

import SwiftData
import SwiftUI

struct RecordingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var viewModel: RecorderViewModel
    
    @State private var isBrowsing = false

    @Query(sort: \RecordingModel.timestamp, order: .reverse)
    private var recordings: [RecordingModel]

    var body: some View {
        NavigationStack {
            if viewModel.isSaving {
                busyView
                    .navigationTitle(Tabs.recordings.title)
            } else {
                listView
                    .toolbar {
                        RecordingsToolbar(isBrowsing: $isBrowsing)
                    }
                    .fileImporter(isPresented: $isBrowsing,
                                  allowedContentTypes: [.audio]) {
                        switch $0 {
                        case .success(let url):
                            self.importAudio(with: url)
                        case .failure(let error):
                            print(error)
                        }
                    }
                    .navigationTitle(Tabs.recordings.title)
            }
        }
    }
    
    var listView: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink {
                    RecordingDetailsView(recording: recording)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    VStack(alignment: .leading) {
                        Text(recording.title)
                            .font(Font.body)
                        HStack {
                            Text(recording.formattedTimestamp)
                                .font(Font.subheadline)
                                .foregroundStyle(Color.secondary)
                            Spacer()
                            Text(recording.formattedLength)
                                .font(Font.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
    
    var busyView: some View {
        ProgressView("Processing file. Please wait.")
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let recording = recordings[index]
                
                if let copiedFileURL = recording.copiedFileURL {
                    viewModel.deleteRecording(url: copiedFileURL)
                }
                modelContext.delete(recording)
            }
            
            do {
                try DataManager.shared.modelContainer.mainContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func importAudio(with url: URL) {
        Task {
            do {
                try await viewModel.importAudio(from: url)
            } catch {
                print(error)
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String {
        absoluteString
    }
}

#Preview {
    RecordingsView()
}

struct RecordingsToolbar: ToolbarContent {
    @Binding var isBrowsing: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                isBrowsing = true
            }, label: {
                Image(systemName: "waveform.badge.plus")
            })
        }
    }
}
