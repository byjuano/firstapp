import SwiftUI

@main
struct AperioApp: App {
    @StateObject private var subscriptionStore = SubscriptionStore()
    @StateObject private var libraryStore = FrameLibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptionStore)
                .environmentObject(libraryStore)
        }
    }
}
