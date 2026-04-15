import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    // ThemeManager arriva dall'App, non lo creiamo qui

    var body: some View {
        Group {
            switch gameViewModel.currentScreen {
            case .home:        HomeView()
            case .playerSetup: PlayerSetupView()
            case .board:       GameBoardView()
            case .recap:       RecapView()
            }
        }
        .environmentObject(gameViewModel)
        .animation(.easeInOut(duration: 0.25), value: gameViewModel.currentScreen)
    }
}
