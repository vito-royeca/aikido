//
//  PlayerbackValue.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import Foundation

struct PlaybackValue: Identifiable {
    let value: Double
    let label: String

    var id: String {
        return "\(label)-\(value)"
    }
}
