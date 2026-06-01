import SwiftUI

/// Home / Today — the daily set (2 review + 1 new), variant A (stacked cards).
/// Handles the awaiting-log, nothing-due, and first-run states from the design.
struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL

    @State private var filter: String? = nil          // nil | "Review" | "New"
    @State private var logTarget: ProblemSummary? = nil

    var body: some View {
        Group {
            if let today = store.today {
                loaded(today)
            } else if store.loadingToday {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = store.todayError {
                errorView(err)
            } else {
                Color.clear
            }
        }
        .background(WF.bg)
        .task { if store.today == nil { await store.loadToday() } }
        .sheet(item: $logTarget) { problem in
            LogSessionView(problem: problem) { await store.markLogged(problem.id) }
        }
    }

    // MARK: - Loaded

    private func loaded(_ today: Today) -> some View {
        let firstRun = today.totalSolved == 0 && today.streak == 0
        let allNew = today.reviewCount == 0
        let cards = filter == nil ? today.set : today.set.filter { $0.kind == filter }
        let doneCount = today.set.filter { store.logged.contains($0.problem.id) }.count
        let nudge = today.set.first { store.opened.contains($0.problem.id) && !store.logged.contains($0.problem.id) }

        return ScrollView {
            VStack(spacing: 0) {
                ProgressStrip(streak: today.streak, solved: today.totalSolved,
                              done: doneCount, total: today.set.count)

                if firstRun {
                    welcomeBanner
                } else if let nudge {
                    nudgeBanner(nudge)
                }

                titleRow(today)
                statRow(today, allNew: allNew)

                LazyVStack(spacing: 12) {
                    ForEach(cards, id: \.problem.id) { card in
                        ProblemCard(
                            card: card,
                            opened: store.opened.contains(card.problem.id),
                            logged: store.logged.contains(card.problem.id),
                            onOpen: { open(card.problem) },
                            onLog: { logTarget = card.problem }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .refreshable { await store.loadToday() }
    }

    private func titleRow(_ today: Today) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today").font(Typo.sans(22, 700)).foregroundStyle(WF.ink)
            Spacer()
            if let d = DateFmt.date(fromLocal: today.date) {
                Text("\(DateFmt.weekday(d)) · \(DateFmt.monthDay(d))")
                    .font(Typo.mono(11.5, 500)).foregroundStyle(WF.ink3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    @ViewBuilder private func statRow(_ today: Today, allNew: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if allNew {
                HStack(spacing: 8) {
                    SetStat(n: "\(today.newCount)", label: "New", isNew: true)
                    SetStat(n: "~\(today.estimatedMinutes)", label: "min")
                }
                Text("Nothing due for review — fresh problems to build your queue.")
                    .font(Typo.sans(11.5)).foregroundStyle(WF.ink2)
            } else {
                HStack(spacing: 8) {
                    SetStat(n: "\(today.reviewCount)", label: "Review", selectable: true,
                            selected: filter == "Review", dim: filter != nil && filter != "Review",
                            onTap: { toggle("Review") })
                    SetStat(n: "\(today.newCount)", label: "New", isNew: true, selectable: true,
                            selected: filter == "New", dim: filter != nil && filter != "New",
                            onTap: { toggle("New") })
                    SetStat(n: "~\(today.estimatedMinutes)", label: "min")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var welcomeBanner: some View {
        HStack(alignment: .top, spacing: 9) {
            Icon(name: .flame, size: 15, color: WF.ink3)
            (Text("Welcome! ").font(Typo.sans(11.5, 700)).foregroundColor(WF.ink)
             + Text("No reviews yet — here’s your first all-new set. Reviews start appearing once you’ve logged a few.")
                .font(Typo.sans(11.5)).foregroundColor(WF.ink2))
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 11).fill(WF.fill2))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(WF.line2, lineWidth: 1))
        .padding(.horizontal, 16).padding(.top, 14)
    }

    private func nudgeBanner(_ card: TodayCard) -> some View {
        Button { logTarget = card.problem } label: {
            HStack(spacing: 9) {
                Circle().fill(WF.accent).frame(width: 6, height: 6)
                (Text("You opened ").font(Typo.sans(12)).foregroundColor(WF.accentText)
                 + Text(card.problem.title).font(Typo.sans(12, 700)).foregroundColor(WF.accentText)
                 + Text(" — how did it go?").font(Typo.sans(12)).foregroundColor(WF.accentText))
                Spacer(minLength: 6)
                Text("Log result →").font(Typo.sans(12, 600)).foregroundStyle(WF.accentText)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 11).fill(WF.accentBg))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(WF.accentLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.top, 14)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Icon(name: .inbox, size: 26, color: WF.ink3)
            Text("Couldn’t load today").font(Typo.sans(15, 650)).foregroundStyle(WF.ink)
            Text(message).font(Typo.sans(12)).foregroundStyle(WF.ink2)
                .multilineTextAlignment(.center)
            Btn(title: "Try again", variant: .outline, size: .sm, icon: .back) {
                Task { await store.loadToday() }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func open(_ p: ProblemSummary) {
        if let url = URL(string: p.lcUrl) { openURL(url) }
        store.markOpened(p.id)
    }

    private func toggle(_ k: String) { filter = (filter == k) ? nil : k }
}
