import Foundation

/// Abstraction over analytics events. Every call is gated behind explicit user consent (see
/// `AppState`/`WelcomeView`), never fires before opt-in. `PostHogAnalytics` implements this when
/// a PostHog project key is configured (see `AnalyticsFactory`); `StubAnalytics` (no-op)
/// otherwise.
protocol AnalyticsProviding: AnyObject {
    var isEnabled: Bool { get set }
    func track(_ event: String, properties: [String: String])
}
