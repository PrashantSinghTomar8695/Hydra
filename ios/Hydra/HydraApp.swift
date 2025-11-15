import SwiftUI

@main
struct HydraApp: App {
    @StateObject private var orchestrator = TaskOrchestrator()
    @StateObject private var networkManager = NetworkManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(orchestrator)
                .environmentObject(networkManager)
        }
    }
}

