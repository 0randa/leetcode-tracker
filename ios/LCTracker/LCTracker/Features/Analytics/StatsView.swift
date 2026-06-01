import SwiftUI

/// Analytics / Stats tab (screen 5). Streak + totals, a weekly solved-trend bar
/// chart, and topics ranked by comfort (strongest / needs work). No-data empty
/// state. All numbers come from `GET /api/analytics`; the client only renders.
struct StatsView: View {
    @State private var data: Analytics?
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        Group {
            if let data {
                loaded(data)
            } else if loading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                errorView(error)
            } else {
                Color.clear
            }
        }
        .background(WF.bg)
        .task { if data == nil { await load() } }
    }

    // MARK: - States

    private func loaded(_ a: Analytics) -> some View {
        let hasData = a.totalSolved > 0 || !a.topics.isEmpty || a.weekly.contains { $0 > 0 }
        return VStack(spacing: 0) {
            header
            if hasData { content(a) } else { emptyState }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Your stats").font(Typo.sans(19, 700)).foregroundStyle(WF.ink)
            Spacer()
            Icon(name: .gear, size: 18, color: WF.ink3).opacity(0.4)
        }
        .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 6)
    }

    private func content(_ a: Analytics) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryRow(a)
                solvedChart(a)
                if !a.topics.isEmpty {
                    // With few topics, one ranked list says it all; only split into
                    // strong/weak once the two slices wouldn't overlap.
                    if a.topics.count > 4 {
                        topicSection("Strongest topics", Array(a.topics.prefix(4)))
                        topicSection("Needs work", Array(a.topics.suffix(4).reversed()))
                    } else {
                        topicSection("Topics by comfort", a.topics)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 16)
        }
        .refreshable { await load() }
    }

    // MARK: - Summary (streak + solved)

    private func summaryRow(_ a: Analytics) -> some View {
        HStack(spacing: 10) {
            summaryCard(icon: .flame, value: "\(a.streak)",
                        unit: a.streak == 1 ? "day streak" : "day streak")
            summaryCard(icon: .check, value: "\(a.totalSolved)", unit: "solved")
        }
    }

    private func summaryCard(icon: WFIcon, value: String, unit: String) -> some View {
        HStack(spacing: 9) {
            Icon(name: icon, size: 16, color: WF.ink2)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value).font(Typo.sans(20, 700)).foregroundStyle(WF.ink)
                Text(unit).font(Typo.sans(11.5, 500)).foregroundStyle(WF.ink3)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WF.line, lineWidth: 1))
    }

    // MARK: - Weekly chart

    private func solvedChart(_ a: Analytics) -> some View {
        let maxV = max(a.weekly.max() ?? 0, 1)
        let labels = DateFmt.lastNWeekdayInitials(a.weekly.count)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow(text: "Problems solved")
                Spacer()
                Text("Last 7 days").font(Typo.mono(10.5, 500)).foregroundStyle(WF.ink3)
            }
            .padding(.bottom, 12)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(a.weekly.enumerated()), id: \.offset) { idx, v in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(v > 0 ? WF.accentBg : WF.fill)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(v > 0 ? WF.accentLine : WF.line, lineWidth: 1))
                            .frame(height: max(CGFloat(v) / CGFloat(maxV) * 86, v > 0 ? 8 : 3))
                            .frame(maxWidth: .infinity)
                        Text(idx < labels.count ? labels[idx] : "")
                            .font(Typo.mono(9, 500)).foregroundStyle(WF.ink3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
            .overlay(alignment: .bottom) {
                Rectangle().fill(WF.line).frame(height: 1).offset(y: -13)
            }
        }
    }

    // MARK: - Topic bars

    private func topicSection(_ title: String, _ topics: [TopicComfort]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Eyebrow(text: title)
            VStack(spacing: 9) {
                ForEach(topics, id: \.topic) { t in topicBar(t) }
            }
        }
    }

    private func topicBar(_ t: TopicComfort) -> some View {
        HStack(spacing: 10) {
            Text(t.topic).font(Typo.sans(12, 500)).foregroundStyle(WF.ink)
                .lineLimit(1).frame(width: 118, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WF.fill)
                    Capsule().fill(WF.accent)
                        .frame(width: geo.size.width * CGFloat(min(t.score / 5, 1)))
                }
            }
            .frame(height: 7)
            Text(String(format: "%.1f", t.score))
                .font(Typo.mono(11, 600)).foregroundStyle(WF.ink2)
                .frame(width: 26, alignment: .trailing)
        }
    }

    // MARK: - Empty / error

    private var emptyState: some View {
        VStack(spacing: 14) {
            Icon(name: .chart, size: 26, color: WF.ink3)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(WF.fill2))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(WF.line2, lineWidth: 1))
            Text("No stats yet").font(Typo.sans(15, 650)).foregroundStyle(WF.ink)
            Text("Solve a few problems and your strong and weak topics — and your trend over time — will show up here.")
                .font(Typo.sans(12.5)).foregroundStyle(WF.ink2)
                .multilineTextAlignment(.center).frame(maxWidth: 240).lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28).padding(.bottom, 40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Icon(name: .inbox, size: 26, color: WF.ink3)
            Text("Couldn’t load stats").font(Typo.sans(15, 650)).foregroundStyle(WF.ink)
            Text(message).font(Typo.sans(12)).foregroundStyle(WF.ink2)
                .multilineTextAlignment(.center)
            Btn(title: "Try again", variant: .outline, size: .sm, icon: .back) {
                Task { await load() }
            }
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func load() async {
        loading = true
        error = nil
        do { data = try await APIClient.shared.analytics() }
        catch let e { error = (e as? APIError)?.errorDescription ?? e.localizedDescription }
        loading = false
    }
}
