//
//  BotView.swift
//  Aikido
//
//  Created by Vito Royeca on 12/15/25.
//

import SwiftUI
import LLM

struct BotView: View {
    @ObservedObject var bot: AIBot
    @State var input = ""
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var id = UUID().uuidString
    @State private var isBusy = false
    
    init(_ bot: AIBot) {
        self.bot = bot
    }
    
    // MARK: - UI Variables and methods
    
    var body: some View {
        VStack(alignment: .leading) {
            outputView
            inputView
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
    }
    
    var outputView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                if !bot.thinking.isEmpty {
                    Text(bot.thinking)
                        .foregroundStyle(.gray)
                        .monospaced()
                        .padding(.bottom, 8)
                }
                Text(bot.output)
                    .monospaced()
                    .padding()
                    .id(id)
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: bot.output) {
                        scrollToBottom()
                    }
            }
        }
    }

    var inputView: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.thinMaterial)
                    .frame(height: 40)
                TextField("Ask the AI", text: $input)
                    .padding(8)
            }
            if isBusy {
                Button(action: stop) {
                    Image(systemName: "xmark")
                }
            } else {
                Button(action: respond) {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
    }
    
    func scrollToBottom() {
        withAnimation {
            scrollProxy?.scrollTo(id, anchor: .bottom)
        }
    }
    
    // MARK: - Business Methods
    
    func respond() {
        isBusy = true

        Task {
            await bot.respond(to: input)
            await MainActor.run {
                isBusy = false
            }
        }
    }
    
    func stop() {
        bot.stop()
        isBusy = false
    }
}
