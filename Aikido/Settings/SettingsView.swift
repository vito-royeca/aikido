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
    
    @Query(sort: \WhisperModel.order)
    private var whisperModels: [WhisperModel]
    
    @Query(sort: \LLMModel.order)
    private var llmModels: [LLMModel]

    @State private var whisperModel: WhisperModel?

    var body: some View {
        NavigationStack {
            formView
                .onAppear {
                    refreshData()
                    loadWhisper()
                }
                .navigationTitle(Tabs.settings.title)
        }
    }
    
    var formView: some View {
        Form {
            Section {
                Picker("Select", selection: $whisperName) {
                    ForEach(whisperModels) { whisperModel in
                        WhisperRowView(whisperModel: whisperModel,
                                       willDownload: self.whisperModel == whisperModel && !whisperModel.isDownloaded,
                                       updateWhisper: updateWhisper(_:))
                            .tag(whisperModel.name)
                    }
                }
                .onChange(of: whisperName) {
                    whisperModel = whisperModels.first { $0.name == whisperName }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Whisper AI Model")
            } footer: {
                Text("General-purpose speech recognition model")
            }
            
            Section {
                Picker("Select", selection: $llmName) {
                    ForEach(llmModels) { llmModel in
                        Text(llmModel.name)
                            .tag(llmModel.name)
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
        for whisperModel in self.whisperModels {
            if FileManager.default.fileExists(atPath: whisperModel.localModelURL.path) &&
                FileManager.default.fileExists(atPath: whisperModel.localCoreMLModelURL.path) {
                whisperModel.isDownloaded = true
            } else {
                whisperModel.isDownloaded = false
            }
        }
    }

    func loadWhisper() {
        whisperModel = whisperModels.first { $0.name == whisperName }
        
        if let whisperModel, whisperModel.isDownloaded {
            WhisperManager.shared.load(whisperModel)
        }
    }
    
    func updateWhisper(_ result: Bool) {
        guard let whisperModel else {
            return
        }

        
        whisperModel.isDownloaded = result
        WhisperManager.shared.load(whisperModel)
    }
}

// MARK: - WhisperRowView

struct WhisperRowView: View {
    @Environment(\.modelContext) private var modelContext

    @State var whisperModel: WhisperModel
    var willDownload: Bool
    var updateWhisper: (Bool) -> Void
    
    var body: some View {
        HStack {
            Text("\(whisperModel.name) \(whisperModel.info)")
            
            Spacer()
            
            if whisperModel.isDownloaded {
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
        
        if let url = URL(string: whisperModel.modelURL) {
            items.append(DownloadItem(sourceURL: url,
                                      destinationURL: whisperModel.localModelURL))
        }
        
        if let url = URL(string: whisperModel.coreMLModelURL) {
            items.append(DownloadItem(sourceURL: url,
                                      destinationURL: whisperModel.localCoreMLModelURL))
        }
        
        return items
    }
}

#Preview {
    SettingsView()
        .modelContainer(DataManager.shared.modelContainer)
}
