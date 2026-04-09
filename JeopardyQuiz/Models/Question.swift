//
//  Question.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//
import Foundation

struct Question: Codable, Identifiable, Equatable {
    let id: Int
    let category: String
    let question: String
    let answer: String
    let value: Int
    var isAnswered: Bool = false
}
