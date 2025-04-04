//
//  AikidoApp.swift
//  Aikido
//
//  Created by Vito Royeca on 3/25/25.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        print(documentsDirectory)
        
        setupData()
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }
}

extension AppDelegate {
    func setupData() {
        do {
            try DataManager.shared.createWhisperFiles()
            WhisperManager.shared.loadDefault()
        } catch {
            print(error)
        }
    }
}

@main
struct AikidoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataManager.shared.modelContainer)
    }
}
