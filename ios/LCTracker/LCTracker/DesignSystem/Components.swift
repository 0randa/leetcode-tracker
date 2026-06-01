import SwiftUI

// Faithful SwiftUI ports of the design's wireframe primitives. Paddings, radii,
// font sizes and colors mirror `wireframe-kit.jsx` exactly.

// MARK: - Icons

/// The design's minimal 1.6px line icons, mapped to the closest SF Symbols and
/// rendered at a light weight to keep the thin-line aesthetic.
enum WFIcon: String {
    case home, list, chart, search, flame, check, chevR, chevD
    case ext, close, filter, plus, clock, back, star, link, gear
    case calendar, trendUp, inbox

    var symbol: String {
        switch self {
        case .home: return "house"
        case .list: return "list.bullet"
        case .chart: return "chart.bar"
        case .search: return "magnifyingglass"
        case .flame: return "flame"
        case .check: return "checkmark"
        case .chevR: return "chevron.right"
        case .chevD: return "chevron.down"
        case .ext: return "arrow.up.right"
        case .close: return "xmark"
        case .filter: return "line.3.horizontal.decrease"
        case .plus: return "plus"
        case .clock: return "clock"
        case .back: return "chevron.left"
        case .star: return "star"
        case .link: return "link"
        case .gear: return "gearshape"
        case .calendar: return "calendar"
        case .trendUp: return "chart.line.uptrend.xyaxis"
        case .inbox: return "tray"
        }
    }
}

struct Icon: View {
    let name: WFIcon
    var size: CGFloat = 18
    var color: Color = WF.ink2
    var bold: Bool = false

    var body: some View {
        Image(systemName: name.symbol)
            .font(.system(size: size * 0.82, weight: bold ? .semibold : .regular))
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Badges

struct Badge: View {
    let text: String
    var fg: Color = WF.ink2
    var bg: Color = WF.fill2
    var bd: Color = WF.line
    var mono: Bool = true
    var leadingIcon: WFIcon? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let leadingIcon { Icon(name: leadingIcon, size: 11, color: fg) }
            Text(text)
                .font(mono ? Typo.mono(10.5, 500) : Typo.sans(10.5, 500))
                .tracking(0.21)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(bg))
        .overlay(Capsule().stroke(bd, lineWidth: 1))
        .fixedSize()
    }
}

/// Difficulty as a grayscale ordinal: mono label + N-of-3 filled segments.
struct DiffBadge: View {
    let difficulty: Difficulty
    var small: Bool = false

    var body: some View {
        let lvl = difficulty.level
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i <= lvl ? WF.ink : WF.fill)
                        .overlay(RoundedRectangle(cornerRadius: 1).stroke(i <= lvl ? WF.ink : WF.line, lineWidth: 1))
                        .frame(width: 3, height: 9)
                }
            }
            Text(difficulty.label)
                .font(Typo.mono(small ? 10 : 10.5, 600))
                .tracking(0.21)
                .foregroundStyle(lvl == 3 ? WF.ink : WF.ink2)
        }
        .padding(EdgeInsets(top: 3, leading: 6, bottom: 3, trailing: 7))
        .background(Capsule().fill(WF.fill2))
        .overlay(Capsule().stroke(WF.line, lineWidth: 1))
        .fixedSize()
    }
}

struct StatusBadge: View {
    let status: ProgressStatus
    var body: some View {
        switch status {
        case .todo: Badge(text: status.label, fg: WF.ink2, bg: WF.fill2, bd: WF.line)
        case .review: Badge(text: status.label, fg: WF.accentText, bg: WF.accentBg, bd: WF.accentLine)
        case .mastered: Badge(text: status.label, fg: .white, bg: WF.ink, bd: WF.ink)
        }
    }
}

struct TopicTag: View {
    let topic: String
    var body: some View {
        Badge(text: topic, fg: WF.ink2, bg: WF.fill2, bd: WF.line2, mono: false)
    }
}

/// The single accent's urgency ramp: neutral (later) → accent text (due) → solid
/// accent fill (overdue). "New" cards show a soft accent "New today" chip.
struct DueChip: View {
    let info: DueInfo?
    let isNew: Bool

    var body: some View {
        if isNew {
            Badge(text: "New today", fg: WF.accentText, bg: WF.accentBg, bd: WF.accentLine)
        } else if let info {
            switch info.state {
            case .overdue:
                Text(info.text)
                    .font(Typo.mono(10.5, 600)).tracking(0.21).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(WF.accent))
                    .fixedSize()
            case .due:
                HStack(spacing: 5) {
                    Circle().fill(WF.accent).frame(width: 5, height: 5)
                    Text(info.text).font(Typo.mono(10.5, 600)).tracking(0.21)
                }
                .foregroundStyle(WF.accentText)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(WF.accentBg))
                .overlay(Capsule().stroke(WF.accentLine, lineWidth: 1))
                .fixedSize()
            case .soon, .scheduled:
                Badge(text: info.text, fg: WF.ink3, bg: WF.fill2, bd: WF.line2)
            }
        }
    }
}

/// Comfort dots 1..5, accent-filled up to `level`.
struct Comfort: View {
    var level: Int = 0
    var size: CGFloat = 7
    var gap: CGFloat = 3
    var showLabel: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: gap) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= level ? WF.accent : WF.fill)
                        .overlay(Circle().stroke(i <= level ? WF.accent : WF.line, lineWidth: 1))
                        .frame(width: size, height: size)
                }
            }
            if showLabel {
                Text("\(level)/5").font(Typo.mono(10)).foregroundStyle(WF.ink3)
            }
        }
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Typo.mono(10.5, 600)).tracking(0.84)
            .foregroundStyle(WF.ink3)
    }
}

// MARK: - Buttons

enum BtnVariant { case primary, outline, ghost, subtle }
enum BtnSize { case sm, md, lg }

struct Btn: View {
    let title: String
    var variant: BtnVariant = .primary
    var size: BtnSize = .md
    var full: Bool = false
    var icon: WFIcon? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let icon { Icon(name: icon, size: size == .sm ? 14 : 16, color: fg) }
                Text(title).font(Typo.sans(fontSize, 600))
            }
            .foregroundStyle(fg)
            .frame(maxWidth: full ? .infinity : nil)
            .padding(.vertical, vPad).padding(.horizontal, hPad)
            .background(RoundedRectangle(cornerRadius: 9).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(bd, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var fontSize: CGFloat { size == .sm ? 12 : size == .md ? 13.5 : 14.5 }
    private var vPad: CGFloat { size == .sm ? 7 : size == .md ? 10 : 13 }
    private var hPad: CGFloat { size == .sm ? 11 : size == .md ? 14 : 16 }
    private var fg: Color {
        switch variant {
        case .primary: return .white
        case .outline: return WF.ink
        case .ghost: return WF.ink2
        case .subtle: return WF.ink
        }
    }
    private var bg: Color {
        switch variant {
        case .primary: return WF.ink
        case .outline: return .white
        case .ghost: return .clear
        case .subtle: return WF.fill2
        }
    }
    private var bd: Color {
        switch variant {
        case .primary: return WF.ink
        case .outline: return WF.line
        case .ghost: return .clear
        case .subtle: return WF.line2
        }
    }
}

// MARK: - Controls

/// N-way segmented control (Onboarding rows, Log outcome, Analytics range).
struct Segmented: View {
    let options: [String]
    @Binding var value: String
    var small: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { o in
                let on = o == value
                Button { value = o } label: {
                    Text(o)
                        .font(Typo.sans(small ? 11 : 12.5, on ? 600 : 500))
                        .foregroundStyle(on ? WF.ink : WF.ink2)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, small ? 5 : 7).padding(.horizontal, small ? 6 : 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(on ? Color.white : Color.clear)
                                .shadow(color: on ? Color.black.opacity(0.06) : .clear, radius: 1, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 9).fill(WF.fill2))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(WF.line2, lineWidth: 1))
    }
}

struct WFToggle: View {
    @Binding var on: Bool
    var body: some View {
        Button { on.toggle() } label: {
            ZStack(alignment: on ? .trailing : .leading) {
                Capsule().fill(on ? WF.ink : WF.fill)
                    .overlay(Capsule().stroke(on ? WF.ink : WF.line, lineWidth: 1))
                    .frame(width: 40, height: 23)
                Circle().fill(.white)
                    .frame(width: 17, height: 17)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    .padding(.horizontal, 2)
            }
            .frame(width: 40, height: 23)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: on)
    }
}

struct Radio: View {
    let on: Bool
    var body: some View {
        Circle()
            .fill(on ? WF.ink : Color.white)
            .overlay(Circle().stroke(on ? WF.ink : WF.line, lineWidth: 1))
            .frame(width: 17, height: 17)
            .overlay(on ? Circle().fill(.white).frame(width: 6, height: 6) : nil)
    }
}

/// Search / text input shell — height 38, hairline border, optional leading icon.
struct WFInput: View {
    var placeholder: String
    @Binding var text: String
    var icon: WFIcon? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Icon(name: icon, size: 16, color: WF.ink3) }
            TextField(placeholder, text: $text)
                .font(Typo.sans(13))
                .foregroundStyle(WF.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 11)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 9).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(WF.line, lineWidth: 1))
    }
}
