import SwiftUI

/// Off-script logging — log a problem the app didn't suggest. Variant A: a single
/// floating "+" (LogFab) opens a find sheet with one smart input (paste a LeetCode
/// URL or search by name). Resolution + search happen on the backend
/// (`GET /api/resolve`). Choosing a match shows a confirm card, then reuses the
/// Log a session sheet. On save, the parent reloads Today and shows a toast.
struct OffScriptView: View {
    /// Called after a session is logged off-script, so Today can refresh + toast.
    let onLogged: (_ title: String) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var matches: [ProblemSummary] = []
    @State private var note: String?
    @State private var searching = false
    @State private var quickPicks: [ProblemSummary] = []

    @State private var chosen: ProblemSummary?      // under confirmation
    @State private var fromUrl = false
    @State private var logTarget: ProblemSummary?   // reuse the Log sheet

    private var typed: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    private var looksLikeUrl: Bool { query.range(of: #"leetcode\.com/problems/"#, options: .regularExpression) != nil }
    private var notFound: Bool { typed && !searching && matches.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            grabber
            head
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let chosen {
                        ConfirmMatchCard(problem: chosen, fromUrl: fromUrl,
                                         onBack: { self.chosen = nil },
                                         onLog: { logTarget = chosen })
                    } else {
                        findBody
                    }
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 18)
            }
        }
        .background(Color.white)
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .task { await loadQuickPicks() }
        .task(id: query) { await runSearch() }
        .sheet(item: $logTarget) { p in
            LogSessionView(problem: p) {
                await onLogged(p.title)
                dismiss()
            }
        }
    }

    // MARK: - Chrome

    private var grabber: some View {
        Capsule().fill(WF.line).frame(width: 36, height: 4)
            .frame(maxWidth: .infinity).padding(.top, 9)
    }

    private var head: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: chosen == nil ? "Log a problem" : "Confirm problem")
                Text(chosen == nil ? "Find a problem" : "Is this the one?")
                    .font(Typo.sans(17, 700)).foregroundStyle(WF.ink)
            }
            Spacer()
            Button { dismiss() } label: {
                Icon(name: .close, size: 15, color: WF.ink2)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8).fill(WF.fill2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.top, 12)
    }

    // MARK: - Find body

    @ViewBuilder private var findBody: some View {
        WFInput(placeholder: "Paste a LeetCode link or search by name",
                text: $query, icon: looksLikeUrl ? .link : .search)

        if looksLikeUrl, let m = matches.first {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Resolved from link")
                ResultRow(problem: m, trailing: .link) { choose(m, fromUrl: true) }
            }
        } else if !matches.isEmpty {
            VStack(spacing: 8) {
                ForEach(matches) { m in ResultRow(problem: m) { choose(m, fromUrl: false) } }
            }
        }

        if notFound {
            notFoundCard
        } else if !typed {
            emptyHint
        }
    }

    private var notFoundCard: some View {
        VStack(spacing: 6) {
            Text("Couldn’t find that one").font(Typo.sans(13, 600)).foregroundStyle(WF.ink)
            Text(note ?? "Check the link or spelling. Brand-new problems sync in later — try again then.")
                .font(Typo.sans(11.5)).foregroundStyle(WF.ink2)
                .multilineTextAlignment(.center).lineSpacing(2)
            Btn(title: "Try again", variant: .outline, size: .sm, icon: .back) { query = "" }
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16).padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 11).fill(WF.fill2))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
            .foregroundStyle(WF.line))
    }

    private var emptyHint: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Icon(name: .search, size: 14, color: WF.ink3)
                Text("Paste a LeetCode link or search by name — log anything you solved, even if it wasn’t in today’s set.")
                    .font(Typo.sans(11.5)).foregroundStyle(WF.ink2).lineSpacing(2)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 9).fill(WF.fill2))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(WF.line2, lineWidth: 1))

            if !quickPicks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Quick picks")
                    ForEach(quickPicks) { p in ResultRow(problem: p) { choose(p, fromUrl: false) } }
                }
            }
        }
    }

    // MARK: - Actions / data

    private func choose(_ p: ProblemSummary, fromUrl: Bool) {
        self.fromUrl = fromUrl
        chosen = p
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { matches = []; note = nil; return }
        // Debounce — `.task(id:)` cancels this when the query changes again.
        try? await Task.sleep(nanoseconds: 280_000_000)
        if Task.isCancelled { return }
        searching = true
        do {
            let r = try await APIClient.shared.resolve(query: q)
            matches = r.matches
            note = r.note
        } catch {
            matches = []; note = nil
        }
        searching = false
    }

    private func loadQuickPicks() async {
        guard quickPicks.isEmpty else { return }
        let titles = ["Two Sum", "Valid Parentheses", "Merge Intervals"]
        var picks: [ProblemSummary] = []
        for t in titles {
            if let m = try? await APIClient.shared.resolve(query: t).matches.first { picks.append(m) }
        }
        quickPicks = picks
    }
}

/// A search / quick-pick result row: title, difficulty + topic, optional trailing
/// badge, and a chevron. Tapping selects it for confirmation.
struct ResultRow: View {
    let problem: ProblemSummary
    var trailing: WFIcon? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(problem.title).font(Typo.sans(13, 600)).foregroundStyle(WF.ink).lineLimit(1)
                    HStack(spacing: 7) {
                        DiffBadge(difficulty: problem.difficulty)
                        Text(problem.topic).font(Typo.mono(11)).foregroundStyle(WF.ink3).lineLimit(1)
                    }
                }
                Spacer(minLength: 6)
                if let trailing { Badge(text: "link", fg: WF.ink2, bg: WF.fill2, bd: WF.line, leadingIcon: trailing) }
                Icon(name: .chevR, size: 16, color: WF.ink3)
            }
            .padding(.horizontal, 12).padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WF.line2, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Confirmation card before reusing the Log sheet: title, difficulty/topic/status,
/// and a contextual note about what logging will do given the tracked status.
struct ConfirmMatchCard: View {
    let problem: ProblemSummary
    let fromUrl: Bool
    let onBack: () -> Void
    let onLog: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 11) {
                if fromUrl {
                    Badge(text: "Resolved from link", fg: WF.ink2, bg: WF.fill2, bd: WF.line,
                          mono: false, leadingIcon: .link)
                }
                Text(problem.title).font(Typo.sans(16, 700)).foregroundStyle(WF.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    DiffBadge(difficulty: problem.difficulty)
                    TopicTag(topic: problem.topic)
                    Spacer(minLength: 0)
                    StatusBadge(status: problem.status)
                }
                HStack(alignment: .top, spacing: 8) {
                    Icon(name: .clock, size: 14, color: WF.ink3)
                    Text(statusNote).font(Typo.sans(11.5)).foregroundStyle(WF.ink2).lineSpacing(2)
                }
                .padding(.horizontal, 11).padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 9).fill(WF.fill2))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(WF.line2, lineWidth: 1))
            }
            .padding(15)
            .background(RoundedRectangle(cornerRadius: 13).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(WF.line, lineWidth: 1))

            HStack(spacing: 9) {
                Btn(title: "Not this one", variant: .outline, size: .lg, action: onBack)
                Btn(title: "Log this", variant: .primary, size: .lg, full: true, icon: .check, action: onLog)
            }
        }
    }

    private var statusNote: String {
        switch problem.status {
        case .review: return "In review — logging now reschedules it from today."
        case .mastered: return "Already mastered — a struggling outcome can pull it back into rotation."
        case .todo: return "Not tracked yet — logging starts its review schedule."
        }
    }
}

/// Floating "+" action button (variant A), bottom-right above the nav.
struct LogFab: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Icon(name: .plus, size: 24, color: .white)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(WF.ink))
                .shadow(color: Color(hex: 0x14141e, alpha: 0.4), radius: 11, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.fab")
    }
}
