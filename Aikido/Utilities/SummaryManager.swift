//
//  SummaryManager.swift
//  Aikido
//
//  Created by Vito Royeca on 12/14/25.
//

import Foundation
import LLM

class SummarizyManager: LLM {
    convenience init() {
        let url = Bundle.main.url(forResource: "tinyllama-1.1b-chat-v1.0.Q2_K", withExtension: "gguf")!
        let systemPrompt = "You are a sentient AI with emotions."
        self.init(from: url, template: .llama(systemPrompt))!
    }
    
    convenience init?(_ update: @escaping (Double) -> Void) async {
        let systemPrompt = "You are a sentient AI with emotions."
        let model = HuggingFaceModel("unsloth/Qwen3-0.6B-GGUF", .Q4_K_M, template: .chatML(systemPrompt))
        try? await self.init(from: model) { progress in update(progress) }
    }
}
