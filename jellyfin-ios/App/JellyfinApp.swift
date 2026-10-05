import JellyfinKit
import SwiftUI

@main
struct JellyfinApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.dark)
                .tint(Theme.text)
                .font(Theme.body)
        }
    }
}

/// Sign-in or the app, with the player over everything and short notices on top.
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        Group {
            if app.session == nil { SignInFlow() } else { MainTabs() }
        }
        .fullScreenCover(item: $app.playing) { PlayerView(request: $0) }
        .overlay(alignment: .top) { notice }
        .onAppear { Timing.mark("root-appeared") }
    }

    @ViewBuilder private var notice: some View {
        if let message = app.userData.failure {
            Text(message).font(Theme.meta).foregroundStyle(Theme.text).padding(12)
                .background(Theme.surface2, in: .rect(cornerRadius: Theme.radius)).padding()
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    app.userData.failure = nil
                }
        }
    }
}
