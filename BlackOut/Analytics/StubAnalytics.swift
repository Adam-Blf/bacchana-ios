import Foundation

/// No-op analytics provider. Ships until a consented analytics backend
/// (PostHog) is wired in; never sends anything anywhere.
final class StubAnalytics: AnalyticsProviding {
    var isEnabled = false

    func track(_ event: String, properties: [String: String] = [:]) {
        // Intentionally empty: no network call without explicit consent.
    }
}
