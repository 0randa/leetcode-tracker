import SwiftUI

/// Streak · total solved · progress through today's set, + reserved gear slot.
struct ProgressStrip: View {
    let streak: Int
    let solved: Int
    let done: Int
    let total: Int

    private var pct: CGFloat { total > 0 ? CGFloat(done) / CGFloat(total) : 0 }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Icon(name: .flame, size: 15, color: WF.ink2)
                Text("\(streak)").font(Typo.sans(14, 700)).foregroundStyle(WF.ink)
                Text("day").font(Typo.sans(11)).foregroundStyle(WF.ink3)
            }
            Rectangle().fill(WF.line2).frame(width: 1, height: 18)
            HStack(spacing: 6) {
                Text("\(solved)").font(Typo.sans(14, 700)).foregroundStyle(WF.ink)
                Text("solved").font(Typo.sans(11)).foregroundStyle(WF.ink3)
            }
            Spacer(minLength: 10)
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    Capsule().fill(WF.fill).frame(width: 48, height: 6)
                    Capsule().fill(WF.ink).frame(width: 48 * pct, height: 6)
                }
                Text("\(done)/\(total)").font(Typo.mono(11, 600)).foregroundStyle(WF.ink2)
            }
            // Reserved Settings slot — dimmed and inert for the MVP.
            Icon(name: .gear, size: 18, color: WF.ink3).opacity(0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(WF.line2).frame(height: 1) }
    }
}

/// Boxed stat chip ("2 Review", "1 New", "~45 min"). Review/New are tappable
/// filters; the minutes chip is static.
struct SetStat: View {
    let n: String
    let label: String
    var isNew: Bool = false
    var selectable: Bool = false
    var selected: Bool = false
    var dim: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        let content = HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(n).font(Typo.sans(17, 700)).foregroundStyle(isNew ? WF.accentText : WF.ink)
            Text(label).font(Typo.sans(11.5, 500)).foregroundStyle(isNew ? WF.accentText : WF.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 11).fill(bg))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(selected ? WF.ink : baseBd, lineWidth: selected ? 2 : 1))
        .opacity(dim ? 0.45 : 1)

        if selectable {
            Button(action: onTap) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var baseBd: Color { isNew ? WF.accentLine : WF.line }
    private var bg: Color {
        if selected { return isNew ? WF.accentBg : WF.fill2 }
        return isNew ? WF.accentBg : .white
    }
}

/// A single Today card (variant A — stacked). Opening on LeetCode flips it to
/// in-progress (amber/accent); it isn't done until logged.
struct ProblemCard: View {
    let card: TodayCard
    let opened: Bool
    let logged: Bool
    var onOpen: () -> Void = {}
    var onLog: () -> Void = {}
    var onDetail: (() -> Void)? = nil

    private var p: ProblemSummary { card.problem }
    private var inProgress: Bool { opened && !logged }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header
            HStack(spacing: 7) {
                DiffBadge(difficulty: p.difficulty)
                TopicTag(topic: p.topic)
                Spacer(minLength: 0)
                Comfort(level: p.comfort, showLabel: true)
            }
            actions
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(logged ? WF.fill2 : .white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
        .shadow(color: logged ? .clear : Color(hex: 0x14161c, alpha: 0.04), radius: 1, y: 1)
        .opacity(logged ? 0.66 : 1)
    }

    private var borderColor: Color {
        logged ? WF.line2 : inProgress ? WF.accentLine : WF.line
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(card.isNew ? "NEW" : "REVIEW")
                        .font(Typo.mono(10, 600)).tracking(0.6)
                        .foregroundStyle(card.isNew ? WF.accentText : WF.ink3)
                    DueChip(info: card.due, isNew: card.isNew)
                    if inProgress {
                        HStack(spacing: 5) {
                            Circle().fill(WF.accent).frame(width: 5, height: 5)
                            Text("In progress").font(Typo.mono(10.5, 600))
                        }
                        .foregroundStyle(WF.accentText)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(WF.accentBg))
                        .overlay(Capsule().stroke(WF.accentLine, lineWidth: 1))
                    }
                }
                Text(p.title)
                    .font(Typo.sans(15.5, 650))
                    .foregroundStyle(WF.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if logged {
                Icon(name: .check, size: 20, color: WF.ink)
            } else if onDetail != nil {
                Icon(name: .chevR, size: 17, color: WF.ink3)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onDetail?() }
    }

    @ViewBuilder private var actions: some View {
        if logged {
            Btn(title: "Logged ✓", variant: .subtle, size: .sm, full: true)
        } else if inProgress {
            HStack(spacing: 8) {
                Btn(title: "Log result", variant: .primary, size: .sm, full: true, icon: .check, action: onLog)
                    .accessibilityIdentifier("card.log")
                Btn(title: "Reopen", variant: .outline, size: .sm, icon: .ext, action: onOpen)
            }
        } else {
            HStack(spacing: 8) {
                Btn(title: "Open in LeetCode", variant: .primary, size: .sm, full: true, icon: .ext, action: onOpen)
                Btn(title: "Log", variant: .outline, size: .sm, action: onLog)
                    .accessibilityIdentifier("card.log")
            }
        }
    }
}
