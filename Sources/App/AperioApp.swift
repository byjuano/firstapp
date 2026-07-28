import SwiftUI

@main
struct AperioApp: App {
    @StateObject private var subscriptionStore = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptionStore)
        }
    }
}
