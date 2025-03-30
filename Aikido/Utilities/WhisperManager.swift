//
//  WhisperManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation

class WhisperManager {
    static let shared = WhisperManager()
    
    private var whisperContext: WhisperContext?
    
    private init() {
        
    }
    
    func load(_ whisperFile: WhisperFile) {
        do {
            copyFile(name: "ggml-\(whisperFile.name).bin")
            copyFile(name: "ggml-\(whisperFile.name)-encoder.mlmodelc")
            
            whisperContext = nil
            whisperContext = try WhisperContext.createContext(path: whisperFile.localModelURL.path())
            
            whisperFile.isDownloaded = true
            print("whisper loaded successfully")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func copyFile(name: String) {
        if let resPath = Bundle.main.resourcePath {
            do {
                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let filteredFiles = dirContents.filter{ $0.starts(with: name) }

                for fileName in filteredFiles {
                    if let documentsURL = documentsURL {
                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
                        let destURL = documentsURL.appendingPathComponent(fileName)
                        
                        do {
                            if !FileManager.default.fileExists(atPath: destURL.path()) {
                                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                            }
                        }
                        catch {
                            print(error)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
