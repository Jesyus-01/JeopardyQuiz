//
//  Player.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

struct Player: Identifiable {
    let id = UUID()
    var name: String = ""
    var avatar: Avatar? = nil        // opzionale, nil finché non scelto
    var score: Int = 0
    var correctAnswers: Int = 0
    var wrongAnswers: Int = 0
    var rank: Int = 0

    // Usato nella validazione del PlayerSetup
    var hasSelectedAvatar: Bool { avatar != nil }
    var hasName: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
}
