//
//  AIBot.swift
//  Aikido
//
//  Created by Vito Royeca on 12/14/25.
//

import Foundation
import LLM

class AIBot: LLM {
    convenience init?(model: String,
                      quantization: Quantization = .Q2_K,
                      template: Template,
                      onProgress: ((Double) -> Void)? = nil) async {
        if let url = Bundle.main.url(forResource: model, withExtension: "gguf") {
            self.init(from: url, template: template)!
        } else {
            let model = HuggingFaceModel(model, quantization, template: template)
            
            try? await self.init(from: model) { progress in
                if let onProgress {
                    onProgress(progress)
                }
            }
        }
    }
    
    func summarize(text: String) async -> String {
        await respond(to: summaryPrompt(for: text))
        return output
    }
    
    private func summaryPrompt(for text: String) -> String {
//        let prompt = """
//        Summarize the following text in a single paragraph, focusing on the main conclusion.\n
//        \(text)
//
//        """
        let prompt = """
            Write a concise summary of the text, return your responses with at most 5 lines that cover the key points of the text.
                \(text)
            SUMMARY:
        """
        return prompt
    }
}
