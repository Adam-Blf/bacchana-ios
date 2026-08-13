import Foundation
import PostHog

/// PostHog analytics provider, EU-hosted, consent-gated. Mirrors the web wrapper
/// (`bacchana-site/src/lib/analytics.ts`): capture stays off until `isEnabled` is explicitly
/// flipped by a consent screen, never pre-ticked (RGPD, cf. CLAUDE.md section 18). Created by
/// `AnalyticsFactory` only when a PostHog project key is configured.
final class PostHogAnalytics: AnalyticsProviding {
    private static let euHost = "https://eu.i.posthog.com"

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            isEnabled ? PostHogSDK.shared.optIn() : PostHogSDK.shared.optOut()
        }
    }

    init(apiKey: String) {
        isEnabled = false
        let config = PostHogConfig(projectToken: apiKey, host: Self.euHost)
        // Manual event tracking only (see `appState.analytics.track(...)` call sites in
        // Screens/*): no autocapture, no implicit screen views or app lifecycle noise before or
        // without consent.
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = false
        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.optOut()
    }

    func track(_ event: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
