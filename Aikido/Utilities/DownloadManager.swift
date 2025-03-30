//
//  DownloadManager.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import Foundation
import SwiftUI

class DownloadManager: NSObject, URLSessionDownloadDelegate, ObservableObject {
    @Published var progress: Double = 0
    private var localURL: URL?
    private var completion: ((Bool) -> Void)?

    func download(from remoteURL: URL, to localURL: URL, completion: @escaping (Bool) -> Void) {
        self.localURL = localURL
        self.completion = completion

        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        
        let downloadTask = session.downloadTask(with: remoteURL)
        downloadTask.resume()
    }
    
//    func download(from remoteURL: URL, to localURL: URL) async {
//        self.localURL = localURL
//        
//        return await withCheckedContinuation { continuation in
//            let configuration = URLSessionConfiguration.default
//            let operationQueue = OperationQueue()
//            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
//            
//            let downloadTask1 = session.downloadTask(with: remoteURL)
//            downloadTask1.resume()
//        }
//    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        Task {
            await MainActor.run {
                progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        
        guard let localURL = localURL else {
            return
        }

        do {
            try FileManager.default.moveItem(at: location,
                                             to: localURL)
            completion?(true)
        } catch {
            print(error)
            completion?(false)
        }
    }
}
