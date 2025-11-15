import Foundation
import Combine

class NetworkManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus: String = "Disconnected"
    
    private var quicClient: QuicClient?
    private var currentConnection: ConnectionInfo?
    
    struct ConnectionInfo {
        let ip: String
        let port: Int
        let token: String
        let deviceId: String
    }
    
    func connect(ip: String, port: Int, token: String, deviceId: String) {
        let info = ConnectionInfo(ip: ip, port: port, token: token, deviceId: deviceId)
        currentConnection = info
        
        quicClient = QuicClient(host: ip, port: port)
        quicClient?.connect { [weak self] success in
            DispatchQueue.main.async {
                self?.isConnected = success
                self?.connectionStatus = success ? "Connected" : "Connection Failed"
            }
        }
    }
    
    func disconnect() {
        quicClient?.disconnect()
        quicClient = nil
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    func sendJobRequest(_ request: JobRequest) async throws -> JobAck {
        guard let client = quicClient else {
            throw NetworkError.notConnected
        }
        return try await client.submitJob(request)
    }
    
    func uploadChunk(_ chunk: ChunkUpload) async throws -> ChunkAck {
        guard let client = quicClient else {
            throw NetworkError.notConnected
        }
        return try await client.uploadChunk(chunk)
    }
}

enum NetworkError: Error {
    case notConnected
    case connectionFailed
    case timeout
}

