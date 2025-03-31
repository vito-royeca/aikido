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
    case calendar
    case record
    case map
    case settings
    
    var title: String {
        switch self {
        case .recordings:
            "Recordings"
        case .calendar:
            "Calendar"
        case .record:
            "Record"
        case .map:
            "Map"
        case .settings:
            "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .recordings:
            "list.dash"
        case .calendar:
            "calendar"
        case .record:
            "microphone.fill"
        case .map:
            "map"
        case .settings:
            "gear"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: ContentTab = .recordings
    @StateObject private var audioRecorder = AudioRecorder()

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
                    
                    Text(ContentTab.calendar.title)
                        .tabItem {
                            Label(ContentTab.calendar.title,
                                  systemImage: ContentTab.calendar.icon)
                        }
                        .tag(ContentTab.calendar)
                    
                    RecorderView()
                        .tabItem {
                            EmptyView()
                        }
                        .tag(ContentTab.record)
                    
                    Text(ContentTab.map.title)
                        .tabItem {
                            Label(ContentTab.map.title,
                                  systemImage: ContentTab.map.icon)
                        }
                        .tag(ContentTab.map)
                    
                    SettingsView()
                        .tabItem {
                            Label(ContentTab.settings.title,
                                  systemImage: ContentTab.settings.icon)
                        }
                        .tag(ContentTab.settings)
                }
                .navigationBarTitle(selectedTab.title)
            }
            
            recordButton
        }
        .environmentObject(audioRecorder)
        .ignoresSafeArea(.keyboard) // usefull so the button doesn't move around on keyboard show
    }
    
    var recordButton: some View {
        Button {
            if audioRecorder.isRecording {
                selectedTab = .recordings
                audioRecorder.stopRecording()
            } else {
                selectedTab = .record
                audioRecorder.startRecording()
            }
        } label: {
            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "microphone.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .tint(Color.white)
        }
        .frame(width: 80, height: 80)
        .background(audioRecorder.isRecording ? Color.red : Color.green)
        .clipShape(Circle())
    }
}

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.modelContainer)
}
