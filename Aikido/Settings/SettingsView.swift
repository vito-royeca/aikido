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
                createData()
                loadWhisper()
            }
    }
    
    var formView: some View {
        Form {
            Section {
                Picker("Select", selection: $whisperName) {
                    ForEach(whisperFiles) { whisperFile in
                        WhisperRowView(whisperFile: whisperFile)
                            .tag(whisperFile.name)
                    }
                }
                .onChange(of: whisperName) {
                    whisperFile = whisperFiles.first { $0.name == whisperName }
                }
                .pickerStyle(.navigationLink)
                
//                    if let whisperFile = whisperFile,
//                       !whisperFile.isDownloaded {
//                        fileDownloadView
//                    }
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
    
//    var fileDownloadView: some View {
//        guard let whisperFile = whisperFile,
//            let modelURL = URL(string: whisperFile.modelURL),
//            let coreModelURL = URL(string: whisperFile.coreMLModelURL) else {
//            return EmptyView()
//        }
//        
//        
//        return FileDownloadView(fileName: "Whisper Model", remoteURL: modelURL, localURL: coreModelURL)
//             .onDownload { result in
//                 update(result: result)
//             }
//    }
}

extension SettingsView {
    func createData() {
        do {
            try DataManager.shared.createWhisperFiles()
        } catch {
            print(error)
        }
    }

    func loadWhisper() {
        whisperFile = whisperFiles.first { $0.name == whisperName }
        
        if let whisperFile = whisperFile {
            WhisperManager.shared.load(whisperFile)
        }
    }

    func update(result: Bool) {
        do {
            guard let whisperFile = whisperFile else {
                return
            }
            
            whisperFile.isDownloaded = result
            try modelContext.save()
            loadWhisper()
        } catch {
            print(error)
        }
    }
}

struct WhisperRowView: View {
    var whisperFile: WhisperFile

    var body: some View {
        HStack {
            if whisperFile.isDownloaded {
                Text("\(Image(systemName: "externaldrive.fill.badge.checkmark")) \(whisperFile.name) \(whisperFile.info)")
            } else {
                Text("\(Image(systemName: "square.and.arrow.down")) \(whisperFile.name) \(whisperFile.info)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(DataManager.shared.modelContainer)
}
