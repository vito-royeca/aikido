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
                Text("List")
                    .tabItem {
                        Label("List", systemImage: "list.dash")
                    }
                    .tag(ContentTab.list)

                Text("Calendar")
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(ContentTab.calendar)
                
                Text("Recording")
                    .tabItem {
                        EmptyView()
                    }
                    .tag(ContentTab.record)
                
                Text("Map")
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
        .ignoresSafeArea(.keyboard) // usefull so the button doesn't move around on keyboard show
    }
    
//    var listView: some View {
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//#if os(macOS)
//            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
//#endif
//            .toolbar {
//#if os(iOS)
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//#endif
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
//    }
}

#Preview {
    ContentView()
        .modelContainer(DataManager.shared.modelContainer)
}
