import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                LibraryView()
            } else {
                WelcomeView(onFinish: { hasCompletedOnboarding = true })
            }
        }
        .tint(Theme.accent)
    }
}
