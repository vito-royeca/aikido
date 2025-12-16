//
//  BotLoaderView.swift
//  Aikido
//
//  Created by Vito Royeca on 12/15/25.
//

import SwiftUI
import LLM

protocol BotLoaderViewDelegae {
    func didLoad(bot: AIBot?)
}

struct BotLoaderView: View {
    let model: String
    let quantization: Quantization
    let template: Template
    var delegate: BotLoaderViewDelegae?

    @State private var progress: CGFloat = 0

    var body: some View {
        progressView
    }
    
    var progressView: some View {
        ProgressView(value: progress) {
            Text("Loading AI...")
        } currentValueLabel: {
            Text(String(format: "%.2f%%", progress * 100))
        }
        .padding()
        .onAppear() {
            loadBot()
        }
    }
    
    func loadBot() {
        Task {
            let bot = await AIBot(model: model,
                                  quantization: quantization,
                                  template: template) { progress in
                self.progress = progress
            }
            
            delegate?.didLoad(bot: bot)
        }
    }
}

#Preview {
    let model = "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
    let quantization: Quantization = .Q2_K
    let template: Template = .chatML("You are a sentient AI with emotions.")
    
    BotLoaderView(model: model,
                  quantization: quantization,
                  template: template)
}
