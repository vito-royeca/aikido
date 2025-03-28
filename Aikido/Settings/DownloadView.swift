//
//  DownloadView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/28/25.
//

import SwiftUI

struct DownloadView: View {
    let progress: Double
        
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(
                        Color.pink.opacity(0.5),
                        lineWidth: 1
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.pink,
                        style: StrokeStyle(
                            lineWidth: 1,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                Rectangle()
                    .frame(width: geometry.size.width/3, height: geometry.size.width/3)
                    .foregroundStyle(Color.pink)
                
            }
        }
    }
}

#Preview {
    @Previewable @State var progress: Double = 0
    
    VStack {
        Spacer()
        DownloadView(progress: progress)
            .frame(width: 100, height: 100)
        Spacer()
        HStack {
            Slider(value: $progress, in: 0...1)
            Button("Reset") {
                progress = 0
            }.buttonStyle(.borderedProminent)
        }
    }
}
