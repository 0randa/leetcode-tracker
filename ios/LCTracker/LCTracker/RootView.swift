import SwiftUI

enum AppTab: Hashable { case today, problems, stats }

/// Three-tab shell (Today · Problems · Stats) with the persistent bottom bar.
/// A reserved ⚙ gear slot lives in each screen header (Settings not built).
struct RootView: View {
    @StateObject private var store = AppStore()
    @State private var tab: AppTab = RootView.launchTab()

    /// Optional launch-argument hook for screenshots / UI tests:
    /// `-initialTab problems|stats` (lands in the argument-domain defaults).
    /// Absent in normal use → Today.
    private static func launchTab() -> AppTab {
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "problems": return .problems
        case "stats": return .stats
        default: return .today
        }
    }

    var body: some View {
        Group {
            if store.needsOnboarding {
                OnboardingView()
            } else {
                VStack(spacing: 0) {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    BottomNav(active: $tab)
                }
            }
        }
        .background(WF.bg.ignoresSafeArea())
        .environmentObject(store)
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .today: TodayView()
        case .problems: ProblemsView()
        case .stats: StatsView()
        }
    }
}

struct BottomNav: View {
    @Binding var active: AppTab
    private let tabs: [(tab: AppTab, label: String, icon: WFIcon)] = [
        (.today, "Today", .home), (.problems, "Problems", .list), (.stats, "Stats", .chart),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tab) { t in
                let on = t.tab == active
                Button { active = t.tab } label: {
                    VStack(spacing: 3) {
                        Icon(name: t.icon, size: 20, color: on ? WF.ink : WF.ink3, bold: on)
                        Text(t.label)
                            .font(Typo.sans(10, on ? 600 : 500))
                            .foregroundStyle(on ? WF.ink : WF.ink3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(t.label)")
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(WF.line2).frame(height: 1) }
    }
}

#Preview {
    RootView()
}
