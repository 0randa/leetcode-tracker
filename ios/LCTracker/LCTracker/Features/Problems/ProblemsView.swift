import SwiftUI

/// Problem list (screen 3) — searchable / filterable catalogue. Rows open detail.
struct ProblemsView: View {
    @State private var items: [ProblemSummary] = []
    @State private var topics: [String] = []
    @State private var loading = false

    @State private var search = ""
    @State private var topic: String? = nil
    @State private var difficulty: Difficulty? = nil
    @State private var status: ProgressStatus? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                head
                if loading && items.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(items) { p in
                                NavigationLink(value: p.id) { row(p) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .background(WF.bg)
            .navigationBarHidden(true)
            .navigationDestination(for: Int.self) { id in
                ProblemDetailView(problemId: id)
            }
        }
        .task { await loadTopics() }
        .task(id: filterKey) { await reload() }
    }

    private var filterKey: String {
        "\(search)|\(topic ?? "")|\(difficulty?.rawValue ?? "")|\(status?.rawValue ?? "")"
    }

    // MARK: - Header

    private var head: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("All problems").font(Typo.sans(19, 700)).foregroundStyle(WF.ink)
                Spacer()
                Text("\(items.count) total").font(Typo.mono(11.5, 500)).foregroundStyle(WF.ink3)
                Icon(name: .gear, size: 18, color: WF.ink3).opacity(0.4)
            }
            WFInput(placeholder: "Search problems…", text: $search, icon: .search)
            HStack(spacing: 7) {
                topicMenu
                difficultyMenu
                statusMenu
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(WF.line2).frame(height: 1) }
    }

    private func filterButton(_ title: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Text(title).font(Typo.sans(11.5, active ? 600 : 500))
                .foregroundStyle(active ? WF.ink : WF.ink2).lineLimit(1)
            Icon(name: .chevD, size: 13, color: WF.ink3)
        }
        .frame(maxWidth: .infinity).frame(height: 31)
        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? WF.ink : WF.line, lineWidth: 1))
    }

    private var topicMenu: some View {
        Menu {
            Button("All topics") { topic = nil }
            ForEach(topics, id: \.self) { t in Button(t) { topic = t } }
        } label: { filterButton(topic ?? "Topic", active: topic != nil) }
    }

    private var difficultyMenu: some View {
        Menu {
            Button("All") { difficulty = nil }
            ForEach(Difficulty.allCases, id: \.self) { d in Button(d.label) { difficulty = d } }
        } label: { filterButton(difficulty?.label ?? "Difficulty", active: difficulty != nil) }
    }

    private var statusMenu: some View {
        Menu {
            Button("All") { status = nil }
            ForEach([ProgressStatus.todo, .review, .mastered], id: \.self) { s in
                Button(s.label) { status = s }
            }
        } label: { filterButton(status?.label ?? "Status", active: status != nil) }
    }

    // MARK: - Row

    private func row(_ p: ProblemSummary) -> some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 6) {
                Text(p.title).font(Typo.sans(13.5, 600)).foregroundStyle(WF.ink).lineLimit(1)
                HStack(spacing: 7) {
                    DiffBadge(difficulty: p.difficulty)
                    Text(p.topic).font(Typo.mono(11)).foregroundStyle(WF.ink3).lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(status: p.status)
                Comfort(level: p.comfort, size: 6, showLabel: true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(WF.line2).frame(height: 1) }
        .contentShape(Rectangle())
    }

    // MARK: - Data

    private func loadTopics() async {
        if topics.isEmpty { topics = (try? await APIClient.shared.topics()) ?? [] }
    }

    private func reload() async {
        loading = true
        do {
            items = try await APIClient.shared.problems(
                search: search, topic: topic, difficulty: difficulty, status: status)
        } catch {
            items = []
        }
        loading = false
    }
}
