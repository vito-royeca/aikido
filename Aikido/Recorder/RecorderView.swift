//
//  RecorderView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import SwiftUI

struct RecorderView: View {
    @EnvironmentObject var viewModel: RecorderViewModel
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle(viewModel.newTitle)
        }
    }
    
    var contentView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                ForEach(viewModel.segments, id: \.id) { segment in
                    Text(segment.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(segment.id)
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onChange(of: viewModel.segments) {
                    scrollToBottom()
                }
            }
        }
    }
    
    func scrollToBottom() {
        withAnimation {
            scrollProxy?.scrollTo(viewModel.segments.last?.id, anchor: .bottom)
        }
    }
}

#Preview {
    RecorderView()
}
