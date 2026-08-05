import SwiftUI

@main
struct BacchusApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.themeMode.colorScheme)
                .task {
                    // Best-effort refresh so a returning premium user sees unlocked packs
                    // without waiting for their first purchase/restore action. No-op in guest
                    // mode (`StubEntitlements.refresh()` does nothing). `isPremium` lives on the
                    // entitlement provider, not as an `@Published` property, so views bound to
                    // `appState` are nudged to re-read it via an explicit `objectWillChange`.
                    await appState.entitlements.refresh()
                    appState.objectWillChange.send()
                }
        }
    }
}
