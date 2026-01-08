//
//  DownloadView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import SwiftUI

protocol DownloadViewDelegate {
    func downloadCompleted(result: Bool)
}

struct DownloadView: View {
    var items: [DownloadItem]
    var delegate: DownloadViewDelegate? = nil

    @State private var progress: Double = 0

    var body: some View {
        progressView
            .onAppear {
                startDownload()
            }
    }
    
    private var progressView: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(
                        Color.accentColor.opacity(0.5),
                        lineWidth: 1
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                Rectangle()
                    .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                    .foregroundStyle(Color.accentColor)
                
            }
        }
    }

    private func startDownload() {
        Task {
            do {
                let model = DownloadViewModel()
                try await model.download(items: items) { progress in
                    self.progress = progress
                }
                delegate?.downloadCompleted(result: true)
            } catch {
                print(error)
                delegate?.downloadCompleted(result: false)
            }
        }
    }
    
    static func defaultDownloadItems() -> [DownloadItem] {
        var items = [DownloadItem]()
        
        WhisperManager.shared.loadDefault()
        if let model = WhisperManager.shared.loadedWhisperModel {
            if let url = URL(string: model.modelURL) {
                items.append(DownloadItem(source: url,
                                          destination: model.localModelURL))
            }
            
            if let url = URL(string: model.coreMLModelURL) {
                items.append(DownloadItem(source: url,
                                          destination: model.localCoreMLModelURL))
            }
        }
        
        return items
    }
}

#Preview {
//    @Previewable @State var progress: Double = 0
    DownloadView(items: DownloadView.defaultDownloadItems())
        .frame(width: 100, height: 100)
}

