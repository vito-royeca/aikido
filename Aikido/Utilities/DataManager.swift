//
//  DataManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/26/25.
//

import Foundation
import SwiftData

class DataManager {
    static let shared = DataManager()
    
    private init() {
        
    }
    
    var modelContainer: ModelContainer = {
        let schema = Schema([
            LLMFile.self,
            Recording.self,
            WhisperFile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    func createWhisperFiles() throws {
        if let url = Bundle.main.url(forResource: "whisper", withExtension: "json") {
            let decoder = JSONDecoder()
            let data = try Data(contentsOf: url)
            let jsonData = try decoder.decode([WhisperFile].self, from: data)
            
            for whisper in jsonData {
                let descriptor = FetchDescriptor<WhisperFile>(predicate: #Predicate { $0.name == whisper.name })
                
                if (try? modelContainer.mainContext.fetch(descriptor))?.first == nil {
                    modelContainer.mainContext.insert(whisper)
                }
            }

            try? modelContainer.mainContext.save()
        }
    }
    
}
