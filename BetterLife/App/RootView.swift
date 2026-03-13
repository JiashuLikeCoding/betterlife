import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            BingoHomeView()
                .tabItem {
                    Label("Bingo", systemImage: "square.grid.4x3.fill")
                }

            Text("花園（稍後）")
                .tabItem {
                    Label("花園", systemImage: "leaf.fill")
                }

            Text("獎勵（稍後）")
                .tabItem {
                    Label("獎勵", systemImage: "gift.fill")
                }
        }
    }
}
