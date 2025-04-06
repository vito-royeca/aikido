//
//  ContentView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/25/25.
//

import SwiftUI
import SwiftData

enum ContentTab {
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
    @State private var selectedTab: ContentTab = .recordings
    @StateObject private var recorderViewModel = RecorderViewModel()
    
    var body: some View {
        tabView
    }

    var tabView: some View {
        ZStack(alignment: .bottom) {
            NavigationView {
                TabView(selection: $selectedTab) {
                    RecordingsView()
                        .tabItem {
                            Label(ContentTab.recordings.title,
                                  systemImage: ContentTab.recordings.icon)
                        }
                        .tag(ContentTab.recordings)
                    
                    RecorderView(isRecording: $recorderViewModel.isRecording)
                        .tabItem {
                            EmptyView()
                        }
                        .tag(ContentTab.record)
                        
                    
                    SettingsView()
                        .tabItem {
                            Label(ContentTab.settings.title,
                                  systemImage: ContentTab.settings.icon)
                        }
                        .tag(ContentTab.settings)
                }
                .onChange(of: selectedTab) {
                    if recorderViewModel.isRecording {
                        selectedTab = .record
                    }
                }
                .navigationBarTitle(selectedTab.title)
            }
            
            recordButton
        }
        .environmentObject(recorderViewModel)
        .ignoresSafeArea(.keyboard) // usefull so the button doesn't move around on keyboard show
    }
    
    var recordButton: some View {
        Button {
            if recorderViewModel.isRecording {
                selectedTab = .recordings
                recorderViewModel.stop()
            } else {
                recorderViewModel.start()
                selectedTab = .record
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
