//
//  PlayerDisplay.swift
//  Aikido
//
//  Created by Vito Royeca on 3/31/25.
//

import Foundation

enum PlayerDisplayConstants {
    static let secsPerMin = 60
    static let secsPerHour = PlayerDisplayConstants.secsPerMin * 60
}


struct PlayerDisplay {
    let elapsedText: String
    let remainingText: String

    static let zero: PlayerDisplay = .init(elapsedTime: 0, remainingTime: 0)

    init(elapsedTime: Double, remainingTime: Double) {
        elapsedText = PlayerDisplay.formatted(time: elapsedTime)
        remainingText = PlayerDisplay.formatted(time: remainingTime)
    }

    private static func formatted(time: Double) -> String {
        var seconds = Int(ceil(time))
        var hours = 0
        var mins = 0

        if seconds > PlayerDisplayConstants.secsPerHour {
            hours = seconds / PlayerDisplayConstants.secsPerHour
            seconds -= hours * PlayerDisplayConstants.secsPerHour
        }

        if seconds > PlayerDisplayConstants.secsPerMin {
            mins = seconds / PlayerDisplayConstants.secsPerMin
            seconds -= mins * PlayerDisplayConstants.secsPerMin
        }

        var formattedString = ""
        if hours > 0 {
            formattedString = "\(String(format: "%02d", hours)):"
        }
        formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", seconds))"
        return formattedString
    }
}
