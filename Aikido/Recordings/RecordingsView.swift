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
    @EnvironmentObject var audioRecorder: AudioRecorder

    @State private var isImporting = false
    @State private var importedURL: URL?

    @Query(sort: \Recording.timestamp, order: .reverse)
    private var recordings: [Recording]

    var body: some View {
        listView
            .fileImporter(isPresented: $isImporting,
                          allowedContentTypes: [.audio]) {
                switch $0 {
                case .success(let url):
                    self.importedURL = url
                case .failure(let error):
                    print(error)
                }
            }
            .toolbar {
                RecordingsToolbar(isImporting: $isImporting)
            }
            .sheet(item: $importedURL) { url in
                TranscriberView(url: url)
            }
            .sheet(item: $audioRecorder.recordedURL) { url in
                TranscriberView(url: url)
            }
    }
    
    var listView: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink {
                    RecordingDetailsView(recording: recording)
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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let recording = recordings[index]
                
                if let copiedFileURL = recording.copiedFileURL {
                    WhisperManager.shared.deleteRecording(url: copiedFileURL)
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
}

extension URL: Identifiable {
    public var id: String {
        absoluteString
    }
}

#Preview {
    RecordingsView()
}

struct RecordingsToolbar: ToolbarContent {
    @Binding var isImporting: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                isImporting = true
            }, label: {
                Image(systemName: "waveform.badge.plus")
            })
        }
    }
}
