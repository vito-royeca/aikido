//
//  SummarizerTestView.swift
//  Aikido
//
//  Created by Vito Royeca on 4/6/25.
//

import SwiftUI
import LLM

struct SummarizerTestView: View {
    @ObservedObject var summarizer = Summarizer()
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State var input = "What's the meaning of life?"
    @State var output = ""
    @State var id = UUID().uuidString
    
    let text = """
         This is the Micro Machine Man presenting the most midget miniature
         motorcade of Michael Machine.
         Each one has dramatic details, perfect trim, precision,
         paint jobs, plus incredible Micro Machine Pocket Place.
         That's physical police station, fire station,
         restaurant, service station, and more.
         Perfect pocket portable to take any place.
         And there are many miniature places to play with.
         Each one comes with its own special edition.
         Micro Machine vehicle and fun, fantastic features
         that miraculously move.
         Raise the bolt lift at the airport, marina, man.
         The gun turret at the army base, clean your car at the car,
         wash, raise it, hulverage.
         And these places fit together to form a Micro Machine world.
         Micro Machine Pocket Place, that's so tremendously
         tiny, so perfectly precise.
         So dazzlingly detailed, you'll want to pocket them all.
         Micro Machines and Micro Machine Pocket Place
         that's sold separately from Galube, the smaller they are, the better they are.
    """
    
    var body: some View {
        VStack(alignment: .leading) {
            contentView
            
            Spacer()
            
            VStack {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).foregroundStyle(.thinMaterial).frame(height: 40)
                        TextField("input", text: $input).padding(8)
                    }
                    Button(action: respond) { Image(systemName: "paperplane.fill") }
                    Button(action: stop) { Image(systemName: "xmark") }
                }
                
                HStack {
                    Button(action: summarize) {
                        Text("Summarize")
                    }
                    Spacer()
                    Button(action: toFrench) {
                        Text("To French")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    var contentView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                Text(summarizer.output)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(id)
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: summarizer.output) {
                        scrollToBottom()
                    }
            }
        }
    }
    
    func scrollToBottom() {
        withAnimation {
            scrollProxy?.scrollTo(id, anchor: .bottom)
        }
    }
    
    func respond() {
        stop()
        Task {
            await summarizer.respond(to: input)
            await MainActor.run {
                id = UUID().uuidString
            }
        }
    }
    
    func stop() {
        summarizer.stop()
    }
    
    func summarize() {
        stop()

        Task {
            await summarizer.respond(to: summaryPrompt(for: text))
            await MainActor.run {
                id = UUID().uuidString
            }
//            let question = summarizer.preprocess(summaryPrompt(for: transcription), [])
//            output = await summarizer.getCompletion(from: question)
//            print(output)
        }
    }
    
    func toFrench() {
        stop()

        Task {
            await summarizer.respond(to: translateToFrench(for: text))
            await MainActor.run {
                id = UUID().uuidString
            }
        }
    }
    
//    func clear() {
//        summarizer.
//    }
    
    private func summaryPrompt(for text: String) -> String {
//        let prompt = """
//        <|begin_of_text|><|start_header_id|>system<|end_header_id|>You are a professional summarizer. Please provide a structured summary of this business meeting, focusing on critical information:
//        - **Updates**: Latest project or team updates.
//        - **Decisions**: Key decisions made during the meeting.
//        - **Next Steps**: Action items and assigned responsibilities.
//        <|eot_id|><|start_header_id|>transcript<|end_header_id|>\(text)<|eot_id|><|start_header_id|>user<|end_header_id|>Summarize this meeting, using the format above, in fewer than 300 words.<|eot_id|>
//        """
        
        
        
        let prompt = """
            Write a concise summary of the text, return your responses with 5 lines that cover the key points of the text.
                \(text)
            SUMMARY:
        """
        
        return prompt
    }
    
    private func translateToFrench(for text: String) -> String {
        let prompt = """
            Translate the following sentence from English to French:

            ```\(text)```

            TRANSLATED SENTENCE:

        """
        
        return prompt
    }
}

#Preview {
    SummarizerTestView()
}
