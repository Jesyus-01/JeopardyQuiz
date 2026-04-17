import Foundation
import Combine

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Navigazione
    @Published var currentScreen: AppScreen = .home

    // MARK: - Giocatori
    @Published var players:           [Player] = []
    @Published var activePlayerIndex: Int      = 0

    // MARK: - Tabellone
    @Published var board:           [[BoardCell]] = []
    @Published var totalQuestions:  Int           = 0
    @Published var playedQuestions: Int           = 0

    // MARK: - Modal domanda
    @Published var selectedCell:    BoardCell? = nil
    @Published var showQuestionModal: Bool     = false
    @Published var answerVisible:   Bool       = false
    @Published var selectedOptionId: String?   = nil

    // MARK: - Fine partita
    @Published var isGameOver: Bool = false

    // MARK: - Dati locali
    private var allCategories: [Category]      = []
    private var allOptions:    [ChoiceOption]  = []
    private var allMedia:      [QuestionMedia] = []

    // MARK: - Setup partita (genera board al volo)
    func setupGame(players: [Player], data: DownloadResponse) {
        self.players       = players
        self.allCategories = data.categories
        self.allOptions    = data.choiceOptions
        self.allMedia      = data.questionMedia
        buildBoard(data: data)
        resetCounters()
    }

    // MARK: - Setup partita da quiz pre-generato
    func setupGame(players: [Player], quiz: SavedQuiz, data: DownloadResponse) {
        self.players       = players
        self.allCategories = data.categories
        self.allOptions    = data.choiceOptions
        self.allMedia      = data.questionMedia

        let loadedBoard   = GeneratedQuizStore.shared.toBoard(quiz)
        board             = loadedBoard
        let allQ          = loadedBoard.flatMap { $0 }.count
        let n             = players.count
        totalQuestions    = (allQ / n) * n   // giri interi: scarta il resto
        resetCounters()
    }

    // MARK: - Costruzione tabellone casuale
    private func buildBoard(data: DownloadResponse) {
        guard let generated = QuizGeneratorService.shared.generateBoard(
            from: data,
            playerCount: players.count
        ) else {
            currentScreen = .home
            return
        }
        board             = generated.cells
        let allQ          = generated.totalQuestions
        let n             = players.count
        totalQuestions    = (allQ / n) * n   // giri interi: scarta il resto
    }

    private func resetCounters() {
        activePlayerIndex = 0
        playedQuestions   = 0
        isGameOver        = false
        currentScreen     = .board
    }

    // MARK: - Selezione cella
    func selectCell(_ cell: BoardCell) {
        guard !cell.isPlayed else { return }
        selectedCell     = cell
        answerVisible    = false
        selectedOptionId = nil
        showQuestionModal = true
    }

    // MARK: - Azioni modal
    func markCorrect() {
        guard let cell = selectedCell else { return }
        players[activePlayerIndex].score          += cell.points
        players[activePlayerIndex].correctAnswers += 1
        closeModal(cell: cell)
    }

    func markWrong() {
        guard let cell = selectedCell else { return }
        players[activePlayerIndex].score       -= cell.points
        players[activePlayerIndex].wrongAnswers += 1
        closeModal(cell: cell)
    }

    func closeWithoutScore() {
        guard let cell = selectedCell else { return }
        closeModal(cell: cell)
    }

    private func closeModal(cell: BoardCell) {
        markCellPlayed(cell)
        playedQuestions += 1
        showQuestionModal = false
        selectedCell      = nil
        if playedQuestions >= totalQuestions {
            endGame()
            return
        }
        activePlayerIndex = (activePlayerIndex + 1) % players.count
    }

    // MARK: - Helpers tabellone
    private func markCellPlayed(_ cell: BoardCell) {
        for col in board.indices {
            for row in board[col].indices {
                if board[col][row].id == cell.id {
                    board[col][row].isPlayed = true
                    return
                }
            }
        }
    }

    func options(for question: Question) -> [ChoiceOption] {
        allOptions
            .filter { $0.questionId == question.questionId }
            .sorted { $0.optionOrder < $1.optionOrder }
    }

    func media(for question: Question) -> QuestionMedia? {
        allMedia.first(where: { $0.questionId == question.questionId })
    }

    func category(for question: Question) -> Category? {
        allCategories.first(where: { $0.categoryId == question.categoryId })
    }

    func localMediaURL(for question: Question) async -> URL? {
        guard let media = media(for: question) else {
            print("❌ Nessun media trovato per question_id: \(question.questionId)")
            return nil
        }
        let subdirectories = bundledSubdirectories(for: question, media: media)
        print("🔍 Cerco '\(media.filename)' in: \(subdirectories)")
        let result = LocalStorageService.shared.resolveMediaURL(
            for: media.filename,
            subdirectories: subdirectories
        )
        print(result != nil ? "✅ Trovato: \(result!.path)" : "❌ Non trovato: \(media.filename)")
        return result
    }

    private func bundledSubdirectories(for question: Question, media: QuestionMedia) -> [String] {
        let normalizedMediaType = media.mediaType.uppercased()
        if question.questionType == .audio || normalizedMediaType == "AUDIO" {
            return ["opening"]
        }
        return ["ambientazione", "personaggio"]
    }

    // MARK: - Fine partita
    private func endGame() {
        let sorted = players.indices.sorted { players[$0].score > players[$1].score }
        for (rank, playerIndex) in sorted.enumerated() {
            players[playerIndex].rank = rank + 1
        }
        isGameOver    = true
        currentScreen = .recap
    }

    var winner: Player? { players.first(where: { $0.rank == 1 }) }

    var rankedPlayers: [Player] { players.sorted { $0.rank < $1.rank } }

    // MARK: - Reset
    func resetGame() {
        players           = []
        board             = []
        activePlayerIndex = 0
        playedQuestions   = 0
        totalQuestions    = 0
        isGameOver        = false
        selectedCell      = nil
        showQuestionModal = false
        currentScreen     = .home
    }

    func preparePlayerSlots(count: Int) {
        players = (1...count).map { i in Player(name: "Giocatore \(i)") }
    }
}
