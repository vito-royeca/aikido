//
//  DownloadManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation
import SwiftUI
import ZIPFoundation

struct DownloadItem: Equatable {
    let sourceURL: URL
    let destinationURL: URL
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sourceURL == rhs.sourceURL &&
        lhs.destinationURL == rhs.destinationURL
    }
}

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var progress: Double = 0
    
    private let operationQueue = OperationQueue()
    private var items = [DownloadItem]()
    
    
    private override init() {
        operationQueue.maxConcurrentOperationCount = 1
    }

    func download(items: [DownloadItem], completion: @escaping (Bool) -> Void) {
        for item in items {
            if !self.items.contains(item),
                !FileManager.default.fileExists(atPath: item.destinationURL.path) {

//                let session = URLSession(configuration: URLSessionConfiguration.default,
//                                         delegate: self,
//                                         delegateQueue: nil)
                let operation = DownloadOperation(session: URLSession.shared,
                                                  downloadTaskURL: item.sourceURL,
                                                  completionHandler: { (localURL, response, error) in
                    self.items.removeAll(where: { $0 == item })
                    self.handleDownloadOperation(url: localURL,
                                                 response: response,
                                                 error: error,
                                                 sourceURL: item.sourceURL,
                                                 destinationURL: item.destinationURL,
                                                 completion: completion)
                })

                self.items.append(item)
                operationQueue.addOperation(operation)
            }
        }
    }
    
    func cancelDownload() {
        operationQueue.cancelAllOperations()
    }

    private func handleDownloadOperation(url: URL?,
                                         response: URLResponse?,
                                         error: Error?,
                                         sourceURL: URL,
                                         destinationURL: URL,
                                         completion: @escaping (Bool) -> Void) {
        if let error {
            completion(false)
            print("download failed \(error)")
            
        } else {
            
            if let url {
                print("downloaded: \(sourceURL.absoluteString)")
                
                do {
                    if sourceURL.path().contains(".zip") {
                        let parentPath = url.deletingLastPathComponent()
                        let lastPath = sourceURL.lastPathComponent.replacingOccurrences(of: ".zip", with: "")
                        
                        try FileManager.default.unzipItem(at: url, to: parentPath, skipCRC32: true)
                        if let unzipPath = URL(string: "\(parentPath)/\(lastPath)") {
                            try FileManager.default.moveItem(at: unzipPath,
                                                             to: destinationURL)
                            try FileManager.default.removeItem(at: url)
                        }
                    } else {
                        try FileManager.default.moveItem(at: url,
                                                         to: destinationURL)
                    }
                    
                    if items.isEmpty {
                        completion(true)
                    }
                } catch {
                    print(error)
                    completion(false)
                }
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    // TODO: handle these
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        Task {
            await MainActor.run {
                progress = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) / Double(items.count)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // do nothing
//        downloadTask.taskIdentifier
    }
}
