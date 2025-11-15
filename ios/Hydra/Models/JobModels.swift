import Foundation

enum JobType: Int {
    case unknown = 0
    case inference = 1
    case preprocess = 2
    case postprocess = 3
    case storage = 4
}

struct JobRequest {
    let jobId: String
    let type: JobType
    let totalChunks: Int
    let metadata: Data
    let timestamp: Int64
    let ttlSeconds: Int64
    let modelName: String
}

struct JobAck {
    let jobId: String
    let accepted: Bool
    let errorCode: Int32
    let errorMessage: String?
    let timestamp: Int64
}

struct ChunkUpload {
    let jobId: String
    let chunkIndex: Int
    let totalChunks: Int
    let data: Data
    let checksum: Data
    let timestamp: Int64
}

struct ChunkAck {
    let jobId: String
    let chunkIndex: Int
    let accepted: Bool
    let errorCode: Int32
    let errorMessage: String?
    let timestamp: Int64
}

struct JobResponse {
    let jobId: String
    let result: InferenceResult?
    let outputData: Data?
    let statusCode: Int32
    let errorCode: Int32
    let errorMessage: String?
    let timestamp: Int64
}

struct InferenceResult {
    let jobId: String
    let outputTensors: [Float]
    let outputShape: [Int32]
    let outputType: Int32
    let rawOutput: Data?
    let metadata: [String: String]
    let inferenceTimeMs: Float
}

