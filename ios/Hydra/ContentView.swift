import SwiftUI

struct ContentView: View {
    @EnvironmentObject var orchestrator: TaskOrchestrator
    @EnvironmentObject var networkManager: NetworkManager
    @State private var showingPairing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if networkManager.isConnected {
                    CaptureView()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("Not Connected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Button("Pair with Samsung") {
                            showingPairing = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Project Hydra")
            .sheet(isPresented: $showingPairing) {
                PairingView()
            }
        }
    }
}

