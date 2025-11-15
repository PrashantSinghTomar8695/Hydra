package com.hydra.jni

class RAMStoreJNI {
    init {
        System.loadLibrary("ramstore")
    }
    
    external fun initialize(maxSizeBytes: Long, snapshotPath: String)
    external fun put(jobId: String, chunkIndex: Int, data: ByteArray, checksum: ByteArray, ttlSeconds: Long): Boolean
    external fun get(jobId: String, chunkIndex: Int): ByteArray?
    external fun getChunkIndices(jobId: String): IntArray
    external fun delete(jobId: String, chunkIndex: Int): Boolean
    external fun deleteJob(jobId: String): Boolean
    external fun snapshot()
    external fun restore()
    external fun emergencyCheckpoint()
    external fun getStats(): com.hydra.ramstore.StoreStats
}

