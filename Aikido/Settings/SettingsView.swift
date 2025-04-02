//
//  SettingsView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/26/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(.settingsWhisperNameKey)
    private var whisperName = "tiny"
        
    @AppStorage(.settingsLLMNameKey)
    private var llmName: String?
    
    @Query(sort: \WhisperFile.order)
    private var whisperFiles: [WhisperFile]
    
    @Query(sort: \LLMFile.order)
    private var llmFiles: [LLMFile]

    @State private var whisperFile: WhisperFile?

    var body: some View {
        formView
            .onAppear {
                refreshData()
                loadWhisper()
            }
    }
    
    var formView: some View {
        Form {
            Section {
                Picker("Select", selection: $whisperName) {
                    ForEach(whisperFiles) { whisperFile in
                        WhisperRowView(whisperFile: whisperFile,
                                       willDownload: self.whisperFile == whisperFile && !whisperFile.isDownloaded,
                                       updateWhisper: updateWhisper(_:))
                            .tag(whisperFile.name)
                    }
                }
                .onChange(of: whisperName) {
                    whisperFile = whisperFiles.first { $0.name == whisperName }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Whisper AI Model")
            } footer: {
                Text("General-purpose speech recognition model")
            }
            
            Section {
                Picker("Select", selection: $llmName) {
                    ForEach(llmFiles) { llmFile in
                        Text(llmFile.name)
                            .tag(llmFile.name)
                    }
                }
            } header: {
                Text("LLM Model")
            } footer: {
                Text("General-purpose AI model")
            }
        }
    }
}

// MARK: - Methods

extension SettingsView {
    func refreshData() {
        for whisperFile in self.whisperFiles {
            if FileManager.default.fileExists(atPath: whisperFile.localModelURL.path) &&
                FileManager.default.fileExists(atPath: whisperFile.localCoreMLModelURL.path) {
                whisperFile.isDownloaded = true
            } else {
                whisperFile.isDownloaded = false
            }
        }
    }

    func loadWhisper() {
        whisperFile = whisperFiles.first { $0.name == whisperName }
        
        if let whisperFile, whisperFile.isDownloaded {
            WhisperManager.shared.load(whisperFile)
        }
    }
    
    func updateWhisper(_ result: Bool) {
        guard let whisperFile else {
            return
        }

        
        whisperFile.isDownloaded = result
        WhisperManager.shared.load(whisperFile)
    }
}

// MARK: - WhisperRowView

struct WhisperRowView: View {
    @Environment(\.modelContext) private var modelContext

    @State var whisperFile: WhisperFile
    var willDownload: Bool
    var updateWhisper: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text("\(whisperFile.name) \(whisperFile.info)")
            
            Spacer()
            
            if whisperFile.isDownloaded {
                Image(systemName: "externaldrive.fill.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                if willDownload {
                    FileDownloadView(items: createDownloadItems())
                        .onDownload { result in
                            updateWhisper(result)
                        }
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
    
    func createDownloadItems() -> [DownloadItem] {
        var items = [DownloadItem]()
        
        if let url = URL(string: whisperFile.modelURL) {
            items.append(DownloadItem(sourceURL: url,
                                      destinationURL: whisperFile.localModelURL))
        }
        
        if let url = URL(string: whisperFile.coreMLModelURL) {
            items.append(DownloadItem(sourceURL: url,
                                      destinationURL: whisperFile.localCoreMLModelURL))
        }
        
        return items
    }
}

#Preview {
    SettingsView()
        .modelContainer(DataManager.shared.modelContainer)
}
