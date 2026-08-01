import Foundation

/// Abstraction over analytics events. Every call is gated behind explicit
/// user consent (see `AppState`/`WelcomeView`), never fires before opt-in.
protocol AnalyticsProviding: AnyObject {
    var isEnabled: Bool { get set }
    func track(_ event: String, properties: [String: String])
}

// TODO(analytics): wire PostHog once a consent screen ships (RGPD: base
// legale = consentement explicite, non pre-coche, cf. CLAUDE.md section 18).
// PostHog sketch (kept commented, not compiled):
//
// final class PostHogAnalytics: AnalyticsProviding {
//     var isEnabled = false
//     func track(_ event: String, properties: [String: String]) {
//         guard isEnabled else { return }
//         PostHogSDK.shared.capture(event, properties: properties)
//     }
// }
