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
    @State private var isPresentingDelete = false
    
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
                    RecordingsRowView(recording: recording)
                }
                .swipeActions(allowsFullSwipe: true) {
                    Button(role: .none) {
                        isPresentingDelete = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(Color.red)
                }
                .confirmationDialog("Delete this Recording?",
                                    isPresented: $isPresentingDelete,
                                    titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        delete(recording: recording)
                    }
                } message: {
                    Text("You cannot undo this action.")
                }
            }
        }
        .listStyle(.plain)
    }
    
    var busyView: some View {
        ProgressView("Processing file. Please wait.")
    }

    private func delete(recording: RecordingModel) {
        withAnimation {
            if let copiedFileURL = recording.copiedFileURL {
                viewModel.deleteRecording(url: copiedFileURL)
            }
            modelContext.delete(recording)
            
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

struct RecordingsRowView: View {
    var recording: RecordingModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(recording.title)
                    .font(Font.body)
                Spacer()
                Text(recording.formattedLength)
                    .font(Font.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            VStack {
                Text(recording.formattedTimestamp)
                    .font(Font.subheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let placeName = recording.placeName {
                    Text(placeName)
                        .font(Font.subheadline)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    RecordingsView()
}

struct RecordingsToolbar: ToolbarContent {
    @Binding var isBrowsing: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isBrowsing = true
            } label: {
                Image(systemName: "waveform.badge.plus")
            }
        }
    }
}
