//
//  RecorderView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import SwiftUI

struct RecorderView: View {
    @EnvironmentObject var viewModel: RecorderViewModel
    
    var body: some View {
        ScrollView {
            Text(viewModel.transcription)
//                .font(.system(size: 16))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color.backgroundSurface)
//                .cornerRadius(10)
        }
    }
}

#Preview {
    RecorderView()
}
