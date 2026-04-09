//
//  TriviaResponse.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation
import UIKit

struct TriviaResponse: Codable {
    let results: [TriviaQuestion]
}

struct TriviaQuestion: Codable {
    let category: String
    let question: String
    let correctAnswer: String
    
    enum CodingKeys: String, CodingKey {
        case category, question
        case correctAnswer = "correct_answer"
    }
}

extension String {
    var htmlDecoded: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil))?
            .string ?? self
    }
}
