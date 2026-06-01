import SwiftUI

/// Temporary scaffold root — replaced by the three-tab shell in the Today slice.
struct RootView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Review Tracker")
                .font(.title2.bold())
            Text("scaffold")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RootView()
}
