import SwiftUI

/// Single source of client state for the daily loop. The backend stays
/// authoritative for scheduling/comfort; this only holds the loaded `Today`
/// payload plus ephemeral per-session UI state (which cards were opened on
/// LeetCode and which have been logged this session).
@MainActor
final class AppStore: ObservableObject {
    @Published var today: Today?
    @Published var loadingToday = false
    @Published var todayError: String?

    /// Cards the user has opened on LeetCode but not yet logged (in-progress).
    @Published private(set) var opened: Set<Int> = []
    /// Cards logged during this session (shown as done before the next reload).
    @Published private(set) var logged: Set<Int> = []

    /// First-run onboarding gate (rate the 18 categories). Local UX state —
    /// the backend stores the ratings as priors but exposes no "done" flag.
    @Published var needsOnboarding: Bool = !UserDefaults.standard.bool(forKey: "onboardingComplete")

    private static let onboardingKey = "onboardingComplete"

    private let api = APIClient.shared

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        needsOnboarding = false
    }

    func loadToday() async {
        loadingToday = true
        todayError = nil
        do {
            today = try await api.today()
        } catch {
            todayError = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        loadingToday = false
    }

    func markOpened(_ id: Int) { opened.insert(id) }

    /// After a successful log: mark the card done locally, then refresh Today so
    /// the new schedule/comfort flow back from the backend.
    func markLogged(_ id: Int) async {
        logged.insert(id)
        opened.remove(id)
        await loadToday()
    }
}
