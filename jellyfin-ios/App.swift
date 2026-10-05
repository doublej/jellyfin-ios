import SwiftUI

@main
struct JellyfinIosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("jellyfin-ios")
                .font(.largeTitle)
            Text("An iOS application")
                .foregroundStyle(.secondary)
            Text(String(localized: "welcome", bundle: L10n.bundle))
            Text(String(format: String(localized: "edit_hint", bundle: L10n.bundle), "App.swift"))
        }
        .padding()
    }
}
