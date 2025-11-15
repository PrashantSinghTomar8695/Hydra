import Foundation
import SwiftUI
import Combine

class TaskOrchestrator: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: String?
    
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Injected dependency - would come from environment in real app
        self.networkManager = NetworkManager()
    }
    
    func submitJob(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let jobId = UUID().uuidString
                let chunkSize = 64 * 1024 // 64KB
                let totalChunks = (imageData.count + chunkSize - 1) / chunkSize
                
                // Create job request
                let request = JobRequest(
                    jobId: jobId,
                    type: .inference,
                    totalChunks: totalChunks,
                    metadata: "{}".data(using: .utf8) ?? Data(),
                    timestamp: Int64(Date().timeIntervalSince1970),
                    ttlSeconds: 300,
                    modelName: "default"
                )
                
                // Submit job
                let ack = try await networkManager.sendJobRequest(request)
                
                if ack.accepted {
                    // Upload chunks
                    for i in 0..<totalChunks {
                        let start = i * chunkSize
                        let end = min(start + chunkSize, imageData.count)
                        let chunkData = imageData.subdata(in: start..<end)
                        
                        let checksum = computeSHA256(chunkData)
                        
                        let chunk = ChunkUpload(
                            jobId: jobId,
                            chunkIndex: i,
                            totalChunks: totalChunks,
                            data: chunkData,
                            checksum: checksum,
                            timestamp: Int64(Date().timeIntervalSince1970)
                        )
                        
                        let chunkAck = try await networkManager.uploadChunk(chunk)
                        
                        if !chunkAck.accepted {
                            throw NSError(domain: "TaskOrchestrator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chunk upload failed"])
                        }
                    }
                    
                    // Wait for result (simplified - would poll or use stream)
                    await MainActor.run {
                        self.lastResult = "Job completed: \(jobId)"
                        self.isProcessing = false
                    }
                } else {
                    throw NSError(domain: "TaskOrchestrator", code: -1, userInfo: [NSLocalizedDescriptionKey: ack.errorMessage ?? "Job rejected"])
                }
            } catch {
                await MainActor.run {
                    self.lastResult = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func computeSHA256(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

// Crypto bridge
import CommonCrypto

private func CC_SHA256(_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    return CommonCrypto.CC_SHA256(data, len, md)
}

