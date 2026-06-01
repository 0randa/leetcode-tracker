import SwiftUI

/// Problem detail / history (screen 7, variant A — timeline). Comfort + trend,
/// next-review date, and the session history. Empty state for never-attempted.
struct ProblemDetailView: View {
    let problemId: Int

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var detail: ProblemDetail?
    @State private var logTarget: ProblemSummary?

    var body: some View {
        VStack(spacing: 0) {
            if let d = detail {
                header(d)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        statBlock(d)
                        if d.history.isEmpty { emptyState } else { timeline(d) }
                    }
                    .padding(16)
                }
                footer(d)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(WF.bg)
        .navigationBarHidden(true)
        .task { await load() }
        .sheet(item: $logTarget) { p in
            LogSessionView(problem: p) { await load() }
        }
    }

    // MARK: - Header

    private func header(_ d: ProblemDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Icon(name: .back, size: 17, color: WF.ink2)
                        Text("Back").font(Typo.sans(12.5, 600)).foregroundStyle(WF.ink2)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Icon(name: .gear, size: 18, color: WF.ink3).opacity(0.4)
            }
            .padding(.horizontal, 12).padding(.top, 10)

            VStack(alignment: .leading, spacing: 0) {
                Text(d.title).font(Typo.sans(19, 700)).foregroundStyle(WF.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 7) {
                    DiffBadge(difficulty: d.difficulty)
                    TopicTag(topic: d.topic)
                    StatusBadge(status: d.status)
                }
                .padding(.top, 10)
                Btn(title: "Open in LeetCode", variant: .outline, size: .sm, icon: .ext) { open(d) }
                    .padding(.top, 12)
            }
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 16)
        }
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(WF.line2).frame(height: 1) }
    }

    // MARK: - Stat block

    private func statBlock(_ d: ProblemDetail) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 9) {
                Eyebrow(text: "Comfort")
                HStack(spacing: 8) {
                    Text("\(d.comfort)").font(Typo.sans(20, 700)).foregroundStyle(WF.ink)
                    Text("/5").font(Typo.mono(11)).foregroundStyle(WF.ink3)
                    Spacer()
                    TrendDots(data: d.comfortTrend)
                }
            }
            .padding(.horizontal, 13).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WF.line, lineWidth: 1))

            VStack(alignment: .leading, spacing: 9) {
                Eyebrow(text: "Next review")
                HStack(spacing: 7) {
                    Icon(name: .calendar, size: 16, color: dueAccent(d) ? WF.accentText : WF.ink2)
                    Text(d.nextReview?.text ?? "Not scheduled")
                        .font(Typo.sans(13, 650)).foregroundStyle(dueAccent(d) ? WF.accentText : WF.ink)
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 13).padding(.vertical, 12)
            .frame(width: 132, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(dueAccent(d) ? WF.accentBg : .white))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(dueAccent(d) ? WF.accentLine : WF.line, lineWidth: 1))
        }
    }

    private func dueAccent(_ d: ProblemDetail) -> Bool {
        d.nextReview?.state == .due || d.nextReview?.state == .overdue
    }

    // MARK: - History

    private func timeline(_ d: ProblemDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "History · \(d.history.count) sessions")
            VStack(spacing: 0) {
                ForEach(Array(d.history.enumerated()), id: \.offset) { idx, s in
                    HistoryRow(session: s, isLast: idx == d.history.count - 1)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Icon(name: .inbox, size: 24, color: WF.ink3)
                .frame(width: 50, height: 50)
                .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(WF.line2, lineWidth: 1))
            Text("Not attempted yet").font(Typo.sans(14, 650)).foregroundStyle(WF.ink)
            Text("No sessions logged for this one. Solve it on LeetCode, then log how it went to start its review schedule.")
                .font(Typo.sans(12)).foregroundStyle(WF.ink2).multilineTextAlignment(.center)
                .frame(maxWidth: 220)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36).padding(.horizontal, 28)
        .background(RoundedRectangle(cornerRadius: 13).fill(WF.fill2))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
            .foregroundStyle(WF.line))
    }

    // MARK: - Footer

    private func footer(_ d: ProblemDetail) -> some View {
        Btn(title: "Log a session", variant: .primary, size: .lg, full: true, icon: .check) {
            logTarget = summary(d)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(WF.line2).frame(height: 1) }
    }

    // MARK: - Helpers

    private func summary(_ d: ProblemDetail) -> ProblemSummary {
        ProblemSummary(id: d.id, slug: d.slug, title: d.title, difficulty: d.difficulty,
                       topics: d.topics, status: d.status, comfort: d.comfort, lcUrl: d.lcUrl)
    }

    private func open(_ d: ProblemDetail) {
        if let url = URL(string: d.lcUrl) { openURL(url) }
    }

    private func load() async {
        detail = try? await APIClient.shared.detail(id: problemId)
    }
}

/// Comfort trend — dot sequence with value labels (variant A).
struct TrendDots: View {
    let data: [Double]
    var body: some View {
        if data.isEmpty {
            EmptyView()
        } else {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(Array(data.enumerated()), id: \.offset) { idx, v in
                    let last = idx == data.count - 1
                    VStack(spacing: 3) {
                        Circle().fill(last ? WF.accent : WF.fill)
                            .overlay(Circle().stroke(last ? WF.accent : WF.line, lineWidth: 1))
                            .frame(width: 8, height: 8)
                        Text("\(Int(v.rounded()))").font(Typo.mono(8)).foregroundStyle(WF.ink3)
                    }
                }
                Icon(name: .trendUp, size: 15, color: WF.ink2).padding(.bottom, 8)
            }
        }
    }
}

/// One timeline history row: outcome dot + connector, outcome/date, metrics.
struct HistoryRow: View {
    let session: Session
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            VStack(spacing: 3) {
                Circle().fill(dotColor).frame(width: 9, height: 9).padding(.top, 3)
                if !isLast { Rectangle().fill(WF.line2).frame(width: 1.5).frame(maxHeight: .infinity) }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(session.outcome.label).font(Typo.sans(12.5, 600)).foregroundStyle(outcomeColor)
                    Spacer()
                    Text(DateFmt.shortDate(fromInstant: session.date))
                        .font(Typo.mono(11)).foregroundStyle(WF.ink3)
                }
                HStack(spacing: 8) {
                    if let t = session.timeTakenMin {
                        Text("⏱ \(t)m").font(Typo.mono(11)).foregroundStyle(WF.ink2)
                    }
                    if let tc = session.timeComplexity {
                        Text("· \(tc) / \(session.spaceComplexity ?? "—")")
                            .font(Typo.mono(11)).foregroundStyle(WF.ink2)
                    }
                    if session.peeked {
                        Badge(text: "peeked", fg: WF.accentText, bg: WF.accentBg, bd: WF.accentLine)
                    }
                    Spacer(minLength: 0)
                    Comfort(level: Int((session.comfort ?? 0).rounded()), size: 5)
                }
                .padding(.bottom, 16)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var outcomeColor: Color {
        switch session.outcome {
        case .solvedClean: return WF.ink
        case .solvedHints: return WF.ink2
        case .didntSolve: return WF.ink3
        }
    }
    private var dotColor: Color { outcomeColor }
}
