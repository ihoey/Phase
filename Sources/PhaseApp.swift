import SwiftUI

@main
struct PhaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var proxyManager = ProxyManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proxyManager)
                .frame(minWidth: 850, minHeight: 550)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
