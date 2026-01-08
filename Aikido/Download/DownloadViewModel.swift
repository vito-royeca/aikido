//
//  DownloadViewModel.swift
//  Aikido
//
//  Created by Vito Royeca on 12/16/25.
//

import Foundation
import ZIPFoundation

class DownloadItem: Equatable {
    let source: URL
    let destination: URL
    
    init(source: URL,
         destination: URL) {
        self.source = source
        self.destination = destination
    }
    
    static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        lhs.source == rhs.source &&
        lhs.destination == rhs.destination
    }
}

public enum DownloadError: Error {
    case network(statusCode: Int)
    case noFilteredURL
    case urlIsNilForSomeReason
}

class DownloadViewModel: ObservableObject {
    
    func download(items: [DownloadItem], updateProgress: @escaping (Double) -> Void) async throws {
        let count = Double(items.count)
        var fractionCompleted = Double(0)
        
        for item in items {
            var observation: NSKeyValueObservation!
            let tempURL: URL = try await withCheckedThrowingContinuation { continuation in
                let task = URLSession.shared.downloadTask(with: item.source) { url, response, error in
                    if let error {
                        return continuation.resume(throwing: error)
                    }
                    
                    guard let url else {
                        return continuation.resume(throwing: DownloadError.urlIsNilForSomeReason)
                    }
                    
                    let statusCode = (response as! HTTPURLResponse).statusCode
                    guard statusCode / 100 == 2 else {
                        return continuation.resume(throwing: DownloadError.network(statusCode: statusCode))
                    }
                    continuation.resume(returning: url)
                }
                observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                    fractionCompleted += progress.fractionCompleted / count
                    updateProgress(fractionCompleted)
                }
                task.resume()
            }

            _ = observation
            print("downloaded: \(item.source.absoluteString)")

            if item.source.path().contains(".zip") {
                unzip(tempURL, to: item.destination)
            } else {
                move(tempURL, to: item.destination)
            }
        }
    }
    
    private func unzip(_ source: URL, to destination: URL) {
        do {
            let parentPath = destination.deletingLastPathComponent()
            try FileManager.default.unzipItem(at: source,
                                              to: parentPath,
                                              skipCRC32: true)
            print("unzipped to: \(destination.absoluteString)")
        } catch {
            print("Error in unzipping: \(error)")
        }
    }
    
    private func move(_ source: URL, to destination: URL) {
        do {
            try FileManager.default.moveItem(at: source,
                                             to: destination)
            print("moved to: \(destination.absoluteString)")
        } catch {
            print("Error in moving: \(error)")
        }
    }
}
