//
//  QuizService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

class QuizService {
    static let shared = QuizService()
    
    func fetchQuestions(amount: Int = 25, completion: @escaping (Result<[Question], Error>) -> Void) {
        guard let url = TriviaAPIService.buildURL(amount: amount) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.zeroByteResource)))
                return
            }
            do {
                let response = try JSONDecoder().decode(TriviaResponse.self, from: data)
                let questions = response.results.enumerated().map { index, raw in
                    Question(
                        id: index,
                        category: raw.category,
                        question: raw.question.htmlDecoded,
                        answer: raw.correctAnswer.htmlDecoded,
                        value: (index % 5 + 1) * 200
                    )
                }
                completion(.success(questions))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}