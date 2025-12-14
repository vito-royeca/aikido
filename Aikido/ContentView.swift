//
//  ContentView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/25/25.
//

import SwiftUI
import SwiftData

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
            "list.dash"
        case .record:
            "microphone.fill"
        case .settings:
            "gear"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tabs = .recordings
    @StateObject private var recorderViewModel = RecorderViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabView
            recordButton
                .disabled(recorderViewModel.isSaving)
        }
        .environmentObject(recorderViewModel)
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

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.modelContainer)
}
