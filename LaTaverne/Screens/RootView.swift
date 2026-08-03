import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            switch appState.route {
            case .welcome:
                WelcomeView()
            case .hub:
                HubView()
            case .borderland:
                BorderlandView()
            case .prompt(let packID):
                PromptView(packID: packID)
            case .roulette:
                RouletteView()
            case .tribunal:
                TribunalView()
            case .recap:
                RecapView()
            }
        }
        .animation(.easeInOut(duration: Theme.Motion.base), value: appState.route)
    }
}
