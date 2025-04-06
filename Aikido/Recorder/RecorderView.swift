//
//  RecorderView.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import SwiftUI

struct RecorderView: View {
    @Binding var isRecording: Bool

    var body: some View {

        Text("Recording...")
    }
}

#Preview {
    RecorderView(isRecording: .constant(true))
}
