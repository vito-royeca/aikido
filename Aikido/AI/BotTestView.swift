//
//  BotTestView.swift
//  Aikido
//
//  Created by Vito Royeca on 4/6/25.
//

import SwiftUI
import LLM

struct BotTestView: View {
    @State var bot: AIBot? = nil
    
    let model = "TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
//    let model = "tinyllama-1.1b-chat-v1.0.Q2_K"
//    let model = "google/gemma-3-1b-it-qat-q4_0-gguf"
    let quantization: Quantization = .Q2_K
    let template: Template = .chatML("You are a sentient AI with emotions.")
//    let template: Template = .gemma
    
    var body: some View {
        NavigationStack {
            if let bot {
                BotView(bot)
                    .toolbar {
                        BotTestToolbar(reloadAction: reloadBot)
                    }
                    .navigationTitle("Bot Test")
            } else {
                BotLoaderView(model: model,
                              quantization: quantization,
                              template: template,
                              delegate: self)
                    .navigationTitle("Bot Test")
            }
        }
    }
    
    func reloadBot() {
        bot = nil
    }
}

struct BotTestToolbar: ToolbarContent {
    var reloadAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                reloadAction()
            } label: {
                Image(systemName: "arrow.trianglehead.clockwise")
            }
        }
    }
}

extension BotTestView: BotLoaderViewDelegae {
    func didLoad(bot: AIBot?) {
        self.bot = bot
    }
}

#Preview {
    BotTestView()
}
