//
//  FileDownloadView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import SwiftUI

struct FileDownloadView: View {
    var items: [DownloadItem]

    @StateObject private var downloadManager = DownloadManager.shared
    @State private var isDownloaded = false

    private var onDownload: ((_ result: Bool) -> Void)?

    init(items: [DownloadItem]) {
        self.items = items
    }

    var body: some View {
        HStack {
            DownloadView(progress: downloadManager.progress)
                .frame(width: 20, height: 20)
        }
        .onAppear {
            download()
        }
    }
    
    func download() {
        downloadManager.download(items: items) { result in
            onDownload?(result)
        }
    }
    
    func onDownload(perform action: @escaping (_ result: Bool) -> Void) -> FileDownloadView {
        var detailView = self
        detailView.onDownload = action
        return detailView
    }
}
