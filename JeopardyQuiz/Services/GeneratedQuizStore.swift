// GeneratedQuizStore.swift

import Foundation
import Combine

@MainActor
class GeneratedQuizStore: ObservableObject {
    static let shared = GeneratedQuizStore()

    @Published var quizzes:      [SavedQuiz] = []
    @Published var isGenerating: Bool        = false
    @Published var errorMessage: String?     = nil

    private let fileName = "generated_quizzes.json"

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    init() { load() }

    // MARK: - Genera tutti gli N quiz
    // Esegue la generazione sul main actor ma in modo non bloccante
    // (QuizGeneratorService è leggero — non serve background thread)
    func generateAll(from data: DownloadResponse) {
        let count = QuizGeneratorService.shared.availableGamesCount(from: data)
        guard count > 0 else {
            errorMessage = "Nessun quiz disponibile nei dati scaricati."
            return
        }

        isGenerating = true
        errorMessage = nil
        var generated: [SavedQuiz] = []

        for _ in 0..<count {
            if let board = QuizGeneratorService.shared.generateBoard(from: data, playerCount: 2) {
                let savedBoard = board.cells.map { column in
                    column.map { cell in SavedBoardCell.from(cell) }
                }
                generated.append(SavedQuiz(
                    id:          UUID(),
                    generatedAt: Date(),
                    board:       savedBoard
                ))
            }
        }

        for i in generated.indices { generated[i].quizNumber = i + 1 }
        quizzes      = generated
        isGenerating = false
        save()
    }

    // MARK: - Elimina un quiz
    func delete(_ quiz: SavedQuiz) {
        quizzes.removeAll { $0.id == quiz.id }
        save()
    }

    // MARK: - Elimina tutti
    func deleteAll() {
        quizzes = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Converte in board nativa
    func toBoard(_ quiz: SavedQuiz) -> [[BoardCell]] {
        quiz.board.map { column in column.map { $0.toBoardCell() } }
    }

    // MARK: - Persistenza
    private func save() {
        guard let data = try? JSONEncoder().encode(quizzes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard
            let data   = try? Data(contentsOf: fileURL),
            let loaded = try? JSONDecoder().decode([SavedQuiz].self, from: data)
        else { return }
        quizzes = loaded
    }
}
