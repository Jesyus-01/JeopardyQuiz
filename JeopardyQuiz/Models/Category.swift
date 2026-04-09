//
//  Category.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    let title: String
    var questions: [Question]
}