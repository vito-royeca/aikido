//
//  RecordingsView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/29/25.
//

import AVFoundation
import SwiftData
import SwiftUI

struct RecordingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false

    @Query(sort: \Recording.timestamp, order: .reverse)
    private var recordings: [Recording]

    var body: some View {
        NavigationStack {
            listView
                .toolbar {
                    RecordingsToolbar(isImporting: $isImporting)
                }
                .navigationBarTitle("Recordings")
                .fileImporter(isPresented: $isImporting,
                              allowedContentTypes: [.audio]) {
                    switch $0 {
                    case .success(let url):
                        importAudio(url: url)
                    case .failure(let error):
                        print(error)
                    }
                }
        }
    }
    
    var listView: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink {
                    Text(recording.title)
                } label: {
                    VStack(alignment: .leading) {
                        Text(recording.title)
                            .font(Font.headline)
                        HStack {
                            Text(recording.formattedTimestamp)
                                .font(Font.subheadline)
                            Spacer()
                            Text(recording.formattedLength)
                                .font(Font.subheadline)
                        }
                    }
                    
                }
            }
            .onDelete(perform: deleteItems)
        }

    }

    private func importAudio(url: URL) {
        let lastPath = url.path().components(separatedBy: "/").last ?? ""
        let recording = Recording(title: lastPath,
                                  timestamp: nil,
                                  length: 0,
                                  audioPath: url.path())

        // get the creationDate
        do {
            if let timestamp = try url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                recording.timestamp = timestamp
            }
        } catch {
            print("\(#function) Error: \(error)")
        }
        
        // get the length
        Task {
            let asset = AVURLAsset(url: url, options: nil)
            let (duration, _) = try await asset.load(.duration, .metadata)
            recording.length = duration.seconds
            modelContext.insert(recording)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(recordings[index])
            }
        }
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
