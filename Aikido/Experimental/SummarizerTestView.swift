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
    
    @State var input = "What's the meaning of life?"
    @State var output = ""
    
    let transcription = """
        Electric masquerade Redemption. Dancing in the masquerade, idle truth and plain sight jaded,
        pop, roll, click, shot, who will I be today or not? Fastened masks can ceiling unknown.
        Mysterious faces chosen to be shown. Plastic smiles, heartless thank you, I love you.
        I see faces in the mirror who I have into clue. From cracks in the facade,
        only reveal the charade, a foundation that needs repair, wallowing and quiet despair.
        Futile search in a world gone sour, arrows of escape bear no flower,
        imprisoned in an uncomfortable cage, do all lead to drugs alcohol and rage.
        Foamy rosy, gilded prisons of lies, futile locks of control men buys, offering no security,
        securely holding captives, fear of rejection, silence's objection. Under cover of spreading
        darkness, behind tightly closed doors bless, enchanting guys of guilt weaver, succeeding only to
        begile the deceiver. Focused through the pain, clear by delicate humble reign, still beauty worth
        preserving, simple appeal made unnerving. These precious things under coats of wings,
        value held shame for gotten in game, living a beautiful, destructive roll, fragile life
        a more precious goal, all wealth could be taken in seconds, New York, Arizona, the Alamo backends.
        From an honored promise damaged goods dispensed, though contact made null warranties still paid
        in full. Technology built to serve has made man its servants, fish biting and enticing lure,
        society is sick, do I have the cure, not many motion, sweet nothing.
    """
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(summarizer.output).monospaced()
            }
            
            Spacer()
            
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
                
                Button(action: toFrench) {
                    Text("To French")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    func respond() {
        stop()
        Task {
            await summarizer.respond(to: input)
        }
    }
    
    func stop() {
        summarizer.stop()
    }
    
    func summarize() {
        stop()

        Task {
            print("start summarizing...")
            await summarizer.respond(to: summaryPrompt(for: transcription))
//            let question = summarizer.preprocess(summaryPrompt(for: transcription), [])
//            output = await summarizer.getCompletion(from: question)
//            print(output)
            print("done summarizing!")
        }
    }
    
    func toFrench() {
        stop()

        Task {
            print("start translating...")
            await summarizer.respond(to: translateToFrench(for: transcription))
            print("done translating!")
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
                ```\(text)```
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
