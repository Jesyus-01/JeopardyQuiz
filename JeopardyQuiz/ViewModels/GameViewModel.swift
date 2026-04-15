import Foundation
import Combine

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Navigazione
    @Published var currentScreen: AppScreen = .home

    // MARK: - Giocatori
    @Published var players: [Player] = []
    @Published var activePlayerIndex: Int = 0

    // MARK: - Tabellone
    @Published var board: [[BoardCell]] = []   // [colonna(categoria)][riga(difficulty)]
    @Published var totalQuestions: Int = 0
    @Published var playedQuestions: Int = 0

    // MARK: - Modal domanda
    @Published var selectedCell: BoardCell? = nil
    @Published var showQuestionModal: Bool = false
    @Published var answerVisible: Bool = false
    @Published var selectedOptionId: String? = nil   // per scelta multipla

    // MARK: - Fine partita
    @Published var isGameOver: Bool = false

    // MARK: - Riferimento ai dati locali
    private var allOptions: [ChoiceOption] = []
    private var allMedia: [QuestionMedia] = []

    // MARK: - Setup partita

    /// Inizializza una nuova partita con i giocatori e i dati scaricati
    func setupGame(players: [Player], data: DownloadResponse) {
        self.players    = players
        self.allOptions = data.choiceOptions
        self.allMedia   = data.questionMedia

        buildBoard(data: data)
        activePlayerIndex = 0
        playedQuestions   = 0
        isGameOver        = false
        currentScreen     = .board
    }

    // MARK: - Costruzione tabellone

    private func buildBoard(data: DownloadResponse) {
        guard let generated = QuizGeneratorService.shared.generateBoard(
            from: data,
            playerCount: players.count
        ) else {
            // Dati insufficienti — torna alla home
            currentScreen = .home
            return
        }

        board          = generated.cells
        totalQuestions = generated.totalQuestions
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
        players[activePlayerIndex].score        -= cell.points
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

        // Controlla fine partita PRIMA di passare il turno
        if playedQuestions >= totalQuestions {
            endGame()
            return
        }

        // Passa al prossimo giocatore (turno circolare)
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

    /// Restituisce le opzioni di scelta multipla per una domanda
    func options(for question: Question) -> [ChoiceOption] {
        allOptions
            .filter { $0.questionId == question.questionId }
            .sorted { $0.optionOrder < $1.optionOrder }
    }

    /// Restituisce il media associato a una domanda (immagine o audio)
    func media(for question: Question) -> QuestionMedia? {
        allMedia.first(where: { $0.questionId == question.questionId })
    }

    /// Percorso locale del file media
    func localMediaURL(for filename: String) async -> URL? {
        let url = LocalStorageService.shared.localMediaURL(for: filename)
        let exists = LocalStorageService.shared.isMediaDownloaded(filename: filename)
        return exists ? url : nil
    }

    // MARK: - Fine partita

    private func endGame() {
        // Calcola rank (ordinamento per punteggio decrescente)
        let sorted = players.indices.sorted {
            players[$0].score > players[$1].score
        }
        for (rank, playerIndex) in sorted.enumerated() {
            players[playerIndex].rank = rank + 1
        }
        isGameOver    = true
        currentScreen = .recap
    }

    /// Giocatore vincitore (rank 1)
    var winner: Player? {
        players.first(where: { $0.rank == 1 })
    }

    /// Giocatori ordinati per classifica finale
    var rankedPlayers: [Player] {
        players.sorted { $0.rank < $1.rank }
    }

    // MARK: - Nuova partita

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
            players = (1...count).map { i in
                Player(name: "Giocatore \(i)")
            }
        }
}
