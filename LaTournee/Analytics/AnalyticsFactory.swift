import Foundation

/// Chooses the analytics provider at launch: `PostHogAnalytics` when a PostHog project key is
/// configured (`LaTournee/Config/Config.xcconfig` + local, gitignored, `Config.local.xcconfig`),
/// `StubAnalytics` (no-op) otherwise. Either way, capture stays off until explicit user consent
/// flips `AnalyticsProviding.isEnabled` (RGPD, cf. CLAUDE.md section 18).
enum AnalyticsFactory {
    private static let infoPlistKey = "POSTHOG_API_KEY"

    static func make() -> AnalyticsProviding {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
              !apiKey.isEmpty else {
            return StubAnalytics()
        }
        return PostHogAnalytics(apiKey: apiKey)
    }
}
