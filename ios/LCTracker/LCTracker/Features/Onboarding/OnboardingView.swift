import SwiftUI

/// Onboarding — rate the 18 NeetCode categories (variant A: 3-way segmented per
/// row). First run only; the ratings seed each topic's comfort prior.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    @State private var topics: [String] = []
    @State private var ratings: [String: String] = [:]   // category -> rating label
    @State private var loading = true
    @State private var submitting = false

    private let options = [TopicRating.comfortable.label, TopicRating.shaky.label, TopicRating.notTried.label]
    private var count: Int { ratings.values.filter { !$0.isEmpty }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(topics, id: \.self) { cat in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(cat).font(Typo.sans(13, 600)).foregroundStyle(WF.ink)
                                Segmented(options: options, value: binding(for: cat), small: true)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            }
            footer
        }
        .background(Color.white.ignoresSafeArea())
        .task { await loadTopics() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Text("</>").font(Typo.mono(13, 700)).foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 7).fill(WF.ink))
                Text("Review Tracker").font(Typo.sans(14, 700)).foregroundStyle(WF.ink)
            }
            .padding(.bottom, 14)
            Text("Where do you stand?").font(Typo.sans(20, 700)).foregroundStyle(WF.ink)
            Text("We pick your daily problems for you. Rate each topic so the first sets land at the right level.")
                .font(Typo.sans(13)).foregroundStyle(WF.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.top, 18).padding(.bottom, 14)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                Capsule().fill(WF.fill).frame(height: 4)
                GeometryReader { geo in
                    Capsule().fill(WF.accent)
                        .frame(width: topics.isEmpty ? 0 : geo.size.width * CGFloat(count) / CGFloat(topics.count), height: 4)
                }
                .frame(height: 4)
            }
            .padding(.bottom, 10)
            Btn(title: submitting ? "Saving…" : "Continue", variant: .primary, size: .lg, full: true, icon: .check) {
                Task { await submit() }
            }
            Text("\(count)/\(topics.count) rated · you can change these later")
                .font(Typo.mono(10.5)).foregroundStyle(WF.ink3)
                .padding(.top, 8)
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 16)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(WF.line2).frame(height: 1) }
    }

    private func binding(for cat: String) -> Binding<String> {
        Binding(get: { ratings[cat] ?? "" }, set: { ratings[cat] = $0 })
    }

    private func loadTopics() async {
        defer { loading = false }
        do { topics = try await APIClient.shared.topics() }
        catch { topics = [] }
    }

    private func submit() async {
        guard !submitting else { return }
        submitting = true
        let payload = ratings.compactMap { (cat, label) -> TopicRatingDTO? in
            guard let r = TopicRating(label: label) else { return nil }
            return TopicRatingDTO(category: cat, rating: r)
        }
        // Priors are an optimization — proceed into the app even if the submit fails.
        try? await APIClient.shared.submitOnboarding(OnboardingRequest(ratings: payload))
        store.completeOnboarding()
        await store.loadToday()
    }
}
