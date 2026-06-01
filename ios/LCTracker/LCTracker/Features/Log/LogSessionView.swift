import SwiftUI

/// Exact Big-O option set (must-have 5 + exponential + multi-variable + escape).
private let BIGO: [String] = ["O(1)", "O(log n)", "O(n)", "O(n log n)", "O(n²)",
                              "O(2ⁿ)", "O(m·n)", "O(V+E)", "O(m+n)", "Other"]
private let BIGO_LABEL: [String: String] = [
    "O(1)": "constant", "O(log n)": "logarithmic", "O(n)": "linear", "O(n log n)": "linearithmic",
    "O(n²)": "quadratic", "O(2ⁿ)": "exponential", "O(m·n)": "grid / 2-D", "O(V+E)": "graph",
    "O(m+n)": "two inputs", "Other": "free text",
]

/// Log a session (screen 4, variant A — bottom sheet). Outcome · peeked · time ·
/// exact Big-O complexity, with a live schedule preview straight from the backend.
struct LogSessionView: View {
    let problem: ProblemSummary
    let onLogged: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var outcomeLabel = SessionOutcome.solvedClean.label
    @State private var peeked = false
    @State private var timeText = ""
    @State private var tc: String? = nil
    @State private var sc: String? = nil
    @State private var openAcc: String? = nil

    @State private var preview: ScheduleResult?
    @State private var saving = false

    private var outcome: SessionOutcome { SessionOutcome(label: outcomeLabel) ?? .solvedClean }

    private func request() -> LogSessionRequest {
        LogSessionRequest(outcome: outcome, peeked: peeked,
                          timeTakenMin: Int(timeText.trimmingCharacters(in: .whitespaces)),
                          timeComplexity: tc, spaceComplexity: sc)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    outcomeField
                    peekedRow
                    timeField
                    complexityFields
                    SchedulePreviewCard(preview: preview, outcome: outcome, peeked: peeked)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
            }
            footer
        }
        .background(Color.white)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .task(id: "\(outcomeLabel)|\(peeked)") { await refreshPreview() }
    }

    // MARK: - Header / footer

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Log session")
                Text(problem.title).font(Typo.sans(17, 700)).foregroundStyle(WF.ink)
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

    private var footer: some View {
        HStack(spacing: 9) {
            Btn(title: "Cancel", variant: .outline, size: .lg) { dismiss() }
            Btn(title: saving ? "Saving…" : "Save & return", variant: .primary, size: .lg,
                full: true, icon: .check) { Task { await save() } }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(WF.line2).frame(height: 1) }
    }

    // MARK: - Fields

    private var outcomeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Outcome").font(Typo.sans(11.5, 600)).foregroundStyle(WF.ink)
            VStack(spacing: 8) {
                ForEach(SessionOutcome.allLabels, id: \.self) { o in
                    Button { outcomeLabel = o } label: {
                        HStack(spacing: 10) {
                            Radio(on: outcomeLabel == o)
                            Text(o).font(Typo.sans(13.5, 500)).foregroundStyle(WF.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(outcomeLabel == o ? WF.fill2 : .white))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(outcomeLabel == o ? WF.ink : WF.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var peekedRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Peeked at the solution?").font(Typo.sans(13, 600)).foregroundStyle(WF.ink)
                Text("shortens the review interval").font(Typo.mono(11)).foregroundStyle(WF.ink3)
            }
            Spacer()
            WFToggle(on: $peeked)
        }
        .padding(.horizontal, 13).padding(.vertical, 11)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(WF.line, lineWidth: 1))
    }

    private var timeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Time taken").font(Typo.sans(11.5, 600)).foregroundStyle(WF.ink)
            HStack(spacing: 8) {
                Icon(name: .clock, size: 16, color: WF.ink3)
                TextField("e.g. 28", text: $timeText)
                    .font(Typo.sans(13)).foregroundStyle(WF.ink)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, 11).frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 9).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(WF.line, lineWidth: 1))
        }
    }

    private var complexityFields: some View {
        VStack(spacing: 8) {
            ComplexityAccordion(label: "Time complexity", hint: nil, value: tc,
                                open: openAcc == "tc",
                                onToggle: { openAcc = openAcc == "tc" ? nil : "tc" },
                                onPick: { tc = $0; openAcc = nil })
            ComplexityAccordion(label: "Space complexity", hint: "usually O(1) or O(n)", value: sc,
                                open: openAcc == "sc",
                                onToggle: { openAcc = openAcc == "sc" ? nil : "sc" },
                                onPick: { sc = $0; openAcc = nil })
        }
    }

    // MARK: - Networking

    private func refreshPreview() async {
        do { preview = try await APIClient.shared.previewSession(problemId: problem.id, body: request()) }
        catch { preview = nil }
    }

    private func save() async {
        guard !saving else { return }
        saving = true
        do {
            _ = try await APIClient.shared.logSession(problemId: problem.id, body: request())
            await onLogged()
            dismiss()
        } catch {
            saving = false
        }
    }
}

private extension SessionOutcome {
    static var allLabels: [String] {
        [SessionOutcome.solvedClean.label, SessionOutcome.solvedHints.label, SessionOutcome.didntSolve.label]
    }
}

/// Expandable Big-O picker — collapsed shows the chosen value; expanded reveals
/// the full grid with plain-language sublabels.
struct ComplexityAccordion: View {
    let label: String
    let hint: String?
    let value: String?
    let open: Bool
    let onToggle: () -> Void
    let onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(Typo.sans(12.5, 600)).foregroundStyle(WF.ink)
                        if let hint { Text(hint).font(Typo.mono(10.5)).foregroundStyle(WF.ink3) }
                    }
                    Spacer()
                    Text(value ?? "Select…").font(Typo.mono(13, 600))
                        .foregroundStyle(value == nil ? WF.ink3 : WF.ink)
                    Icon(name: .chevD, size: 15, color: WF.ink3)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .padding(.horizontal, 13).padding(.vertical, 11)
            }
            .buttonStyle(.plain)

            if open {
                let cols = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
                LazyVGrid(columns: cols, spacing: 6) {
                    ForEach(BIGO, id: \.self) { o in
                        let on = o == value
                        Button { onPick(o) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(o).font(Typo.mono(12.5, 600)).foregroundStyle(on ? .white : WF.ink)
                                if o != "Other" {
                                    Text(BIGO_LABEL[o] ?? "").font(Typo.sans(9.5))
                                        .foregroundStyle(on ? Color.white.opacity(0.65) : WF.ink3)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(on ? WF.ink : .white))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? WF.ink : WF.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(WF.fill2)
                .overlay(alignment: .top) { Rectangle().fill(WF.line2).frame(height: 1) }
            }
        }
        .background(RoundedRectangle(cornerRadius: 11).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(open ? WF.ink : WF.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

/// Live "What this schedules" card — next review + comfort move from the backend.
struct SchedulePreviewCard: View {
    let preview: ScheduleResult?
    let outcome: SessionOutcome
    let peeked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "What this schedules")
                Spacer()
                Icon(name: .calendar, size: 15, color: WF.accentText)
            }
            if let pv = preview {
                row("Next review", trailing: {
                    HStack(spacing: 4) {
                        if let d = DateFmt.date(fromLocal: pv.reviewDate) {
                            Text(DateFmt.monthDay(d)).font(Typo.sans(13, 650)).foregroundStyle(WF.ink)
                        }
                        Text("· in \(pv.intervalDays)d").font(Typo.mono(11)).foregroundStyle(WF.accentText)
                    }
                })
                row("Comfort", trailing: {
                    HStack(spacing: 8) {
                        dots(pv.comfortFrom, dim: true)
                        Text("→").font(Typo.mono(11)).foregroundStyle(WF.ink3)
                        dots(pv.comfortTo, dim: false)
                        Text("\(fmt(pv.comfortFrom)) → \(fmt(pv.comfortTo))")
                            .font(Typo.mono(11, 600)).foregroundStyle(WF.ink2)
                    }
                })
                Divider().overlay(WF.accentLine)
                Text(note(pv)).font(Typo.sans(11)).foregroundStyle(WF.ink2)
            } else {
                Text("Pick an outcome to preview the schedule.")
                    .font(Typo.sans(11)).foregroundStyle(WF.ink3)
            }
        }
        .padding(.horizontal, 13).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(WF.accentBg))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(WF.accentLine, lineWidth: 1))
    }

    private func row<T: View>(_ label: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Text(label).font(Typo.sans(12)).foregroundStyle(WF.ink2)
            Spacer()
            trailing()
        }
    }

    private func dots(_ level: Double, dim: Bool) -> some View {
        let n = Int(level.rounded())
        return HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= n ? (dim ? WF.accentMute : WF.accent) : WF.fill)
                    .overlay(Circle().stroke(i <= n ? (dim ? WF.accentMute : WF.accent) : WF.line, lineWidth: 1))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func note(_ pv: ScheduleResult) -> String {
        if outcome == .didntSolve { return "Reset to the short interval — back in rotation soon." }
        if peeked && pv.slipped { return "Peeking slipped it back a step." }
        if peeked { return "Peeking holds it at this interval." }
        if outcome == .solvedHints { return "Hints — held at the current interval." }
        return "Clean solve — advances to the next interval."
    }
}
