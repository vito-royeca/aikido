//
//  ContentView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/25/25.
//

import SwiftUI
import SwiftData
import LLM

enum Tabs: Equatable, Hashable {
    case recordings
    case record
    case settings
    
    var title: String {
        switch self {
        case .recordings:
            "Recordings"
        case .record:
            "Record"
        case .settings:
            "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .recordings:
            "waveform"
        case .record:
            "microphone.fill"
        case .settings:
            "gear"
        }
    }
}

@Observable
class ContentViewState {
    var isShowingRecordButton = true
    var bot: AIBot?
}

extension EnvironmentValues {
  @Entry var contentViewState = ContentViewState()
}

struct ContentView: View {
    @StateObject private var recorderViewModel = RecorderViewModel()
    @State private var selectedTab: Tabs = .recordings
    @State private var viewState = ContentViewState()
    
    private let model = "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
    private let quantization: Quantization = .Q2_K
    private let template: Template = .chatML("You are a sentient AI with emotions.")
    
    var body: some View {
        if let _ = viewState.bot {
            contentView
        } else {
            BotLoaderView(model: model,
                          quantization: quantization,
                          template: template,
                          delegate: self)
        }
    }

    var contentView: some View {
        ZStack(alignment: .bottom) {
            tabView
            if viewState.isShowingRecordButton {
                recordButton
                    .disabled(recorderViewModel.isSaving)
            }
        }
        .environmentObject(recorderViewModel)
        .environment(\.contentViewState, viewState)
        .ignoresSafeArea(.keyboard) // usefull so the button doesn't move around on keyboard show
    }

    var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(Tabs.recordings.title,
                systemImage: Tabs.recordings.icon,
                value: .recordings) {
                RecordingsView()
            }
            .disabled(recorderViewModel.isRecording || recorderViewModel.isSaving)

            Tab(value: .record) {
                RecorderView()
            }

            Tab(Tabs.settings.title,
                systemImage: Tabs.settings.icon,
                value: .settings) {
                SettingsView()
            }
            .disabled(recorderViewModel.isRecording || recorderViewModel.isSaving)
        }
        .tabViewStyle(.sidebarAdaptable)
    }
    
    var recordButton: some View {
        Button {
            if recorderViewModel.isRecording {
                recorderViewModel.stop()
                selectedTab = .recordings
            } else {
                selectedTab = .record
                recorderViewModel.start()
            }

        } label: {
            Image(systemName: recorderViewModel.isRecording ? "stop.fill" : "microphone.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .tint(Color.white)
        }
        .frame(width: 80, height: 80)
        .background(recorderViewModel.isRecording ? Color.red : Color.green)
        .clipShape(Circle())
    }
}

extension ContentView: BotLoaderViewDelegae {
    func didLoad(bot: AIBot?) {
        viewState.bot = bot
        recorderViewModel.bot = bot
    }
}

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.modelContainer)
}
