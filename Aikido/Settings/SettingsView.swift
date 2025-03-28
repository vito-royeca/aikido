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
    private var whisperName = ""
        
    @AppStorage(.settingsLLMNameKey)
    private var llmName = ""
    
    @Query(sort: \WhisperFile.order)
    private var whisperFiles: [WhisperFile]
    
    @Query(sort: \LLMFile.order)
    private var llmFiles: [LLMFile]

    @State private var whisperFile: WhisperFile?

    var body: some View {
        formView
            .navigationBarTitle("Settings")
            .onAppear {
                createData()
                loadWhisper()
            }
    }
    
    var formView: some View {
        NavigationStack {
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
                    
                    if let whisperFile = whisperFile {
                        WhisperDetailView(whisperFile: whisperFile)
                            .onDownload { result in
                                update(result: result)
                            }
                    }
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
            .navigationBarTitle("Settings")
        }
    }
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
