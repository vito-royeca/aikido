//
//  ContentView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/25/25.
//

import SwiftUI
import SwiftData

enum ContentTab {
    case list
    case calendar
    case record
    case map
    case settings
}

struct ContentView: View {
    @State private var selectedTab: ContentTab = .list
    
    var body: some View {
        tabView
    }

    var tabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                RecordingsView()
                    .tabItem {
                        Label("List", systemImage: "list.dash")
                    }
                    .tag(ContentTab.list)

                Text("Calendar")
                    .navigationBarTitle("Calendar")
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(ContentTab.calendar)
                
                Text("Record")
                    .navigationBarTitle("Record")
                    .tabItem {
                        EmptyView()
                    }
                    .tag(ContentTab.record)
                
                Text("Map")
                    .navigationBarTitle("Map")
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(ContentTab.map)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(ContentTab.settings)
            }
            recordButton
        }
        .ignoresSafeArea(.keyboard) // usefull so the button doesn't move around on keyboard show
    }
    
    var recordButton: some View {
        Button {
            print("recording...")
            selectedTab = .record
        } label: {
            Image(systemName: "microphone.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .tint(Color.white)
        }
        .frame(width: 80, height: 80)
        .background(Color.green)
        .clipShape(Circle())
    }
}

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.modelContainer)
}
