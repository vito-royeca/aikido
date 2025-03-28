//
//  WhisperDetailView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import SwiftUI

struct WhisperDetailView: View {
    var whisperFile: WhisperFile

    @State private var downloadTask: URLSessionDownloadTask?
    @State private var progress = 0.0
    @State private var observation: NSKeyValueObservation?
    @State private var isDownloaded = false
    
    private var onDownload: ((_ result: Bool) -> Void)?

    var body: some View {
        HStack {
            Text("\(whisperFile.name) \(whisperFile.info)")

            Spacer()

            if isDownloaded {
                Image(systemName: "externaldrive.fill.badge.checkmark")
            } else {
                DownloadView(progress: progress)
                    .frame(width: 20, height: 20)
            }
        }
        .onAppear {
            isDownloaded = whisperFile.isDownloaded
            download()
        }
    }
    
    init(whisperFile: WhisperFile) {
        self.whisperFile = whisperFile
    }
    
    func download() {
        guard  let url = URL(string: whisperFile.downloadURL),
            !whisperFile.isDownloaded else {
            return
        }
        
        downloadTask = URLSession.shared.downloadTask(with: url) { temporaryURL, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }

            do {
                if let temporaryURL = temporaryURL {
                    try FileManager.default.copyItem(at: temporaryURL,
                                                     to: whisperFile.fileURL)
                    isDownloaded = true
                    onDownload?(true)
                }
            } catch let err {
                print("Error: \(err.localizedDescription)")
            }
        }

        observation = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
            self.progress = progress.fractionCompleted
        }

        downloadTask?.resume()
    }
    
    func onDownload(perform action: @escaping (_ result: Bool) -> Void) -> WhisperDetailView {
        var detailView = self
        detailView.onDownload = action
        return detailView
    }
}
