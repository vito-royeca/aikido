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
    @State private var isDownloading = false
    
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
    
    private var formView: some View {
        Form {
            whisperSection
            llmSection
        }
    }
    
    private var whisperSection: some View {
        Section {
            let text = isDownloading ? "Downloading..." : "Select"
            Picker(text, selection: $whisperName) {
                ForEach(whisperModels) { whisperModel in
                    WhisperRowView(whisperModel: whisperModel,
                                   isDownloading: isDownloading,
                                   downloadItems: createDownloadItems(),
                                   delegate: self)
                        .tag(whisperModel.name)
                }
            }
            .onChange(of: whisperName) {
                whisperModel = whisperModels.first { $0.name == whisperName }
                isDownloading = !(whisperModel?.isDownloaded ?? false)
            }
            .pickerStyle(.navigationLink)
            .disabled(isDownloading)
        } header: {
            Text("Whisper AI Model")
        } footer: {
            Text("General-purpose speech recognition model")
        }
    }
    
    private var llmSection: some View {
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
    
    func createDownloadItems() -> [DownloadItem] {
        var items = [DownloadItem]()
        
        guard let whisperModel else {
            return items
        }
        
        if let url = URL(string: whisperModel.modelURL) {
            items.append(DownloadItem(source: url,
                                      destination: whisperModel.localModelURL))
        }
        
        if let url = URL(string: whisperModel.coreMLModelURL) {
            items.append(DownloadItem(source: url,
                                      destination: whisperModel.localCoreMLModelURL))
        }
        
        return items
    }
}

// MARK: - DownloadViewDelegate

extension SettingsView: DownloadViewDelegate {
    func downloadCompleted(result: Bool) {
        guard let whisperModel else {
            return
        }

        whisperModel.isDownloaded = result
        isDownloading = false
        if result {
            WhisperManager.shared.load(whisperModel)
        }
    }
}

// MARK: - WhisperRowView

struct WhisperRowView: View {
    @State var whisperModel: WhisperModel
    var isDownloading: Bool
    var downloadItems: [DownloadItem]
    var delegate: DownloadViewDelegate
    
    var body: some View {
            HStack {
                Text("\(whisperModel.name) \(whisperModel.info)")
                if whisperModel.isDownloaded {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                } else {
                    if isDownloading {
                        DownloadView(items: downloadItems,
                                     delegate: delegate)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
            }
        .onAppear {
            print("isDownloading=\(isDownloading)")
        }
    }
}

// To delete Preview data:
// xcrun simctl --set previews delete all
#Preview {
    SettingsView()
        .modelContainer(DataManager.shared.modelContainer)
}
