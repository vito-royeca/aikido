//
//  FileDownloadView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import SwiftUI

struct FileDownloadView: View {
    var fileName: String
    var remoteURL: URL
    var localURL: URL

    @StateObject private var downloadManager = DownloadManager()
    @State private var isDownloaded = false
    
    private var onDownload: ((_ result: Bool) -> Void)?

    var body: some View {
        HStack {
            Text(fileName)

            Spacer()

            DownloadView(progress: downloadManager.progress)
                .frame(width: 20, height: 20)
        }
        .onAppear {
            download()
        }
    }
    
    init(fileName: String,
         remoteURL: URL,
         localURL: URL) {
        self.fileName = fileName
        self.remoteURL = remoteURL
        self.localURL = localURL
    }
    
    func download() {
        downloadManager.download(from: remoteURL,
                                 to: localURL) { result in
            onDownload?(result)
        }
    }
    
    func onDownload(perform action: @escaping (_ result: Bool) -> Void) -> FileDownloadView {
        var detailView = self
        detailView.onDownload = action
        return detailView
    }
}
