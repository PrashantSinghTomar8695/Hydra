package com.hydra.ramstore

import android.content.Context
import com.hydra.jni.RAMStoreJNI

class RAMObjectStore private constructor(
    private val context: Context,
    private val maxSizeBytes: Long
) {
    private val jni = RAMStoreJNI()
    
    init {
        val snapshotDir = context.filesDir.resolve("ram_store_snapshots")
        snapshotDir.mkdirs()
        jni.initialize(maxSizeBytes, snapshotDir.absolutePath)
    }
    
    fun put(jobId: String, chunkIndex: Int, data: ByteArray, ttlSeconds: Long = 300): Boolean {
        val checksum = computeChecksum(data)
        return jni.put(jobId, chunkIndex, data, checksum, ttlSeconds)
    }
    
    fun get(jobId: String, chunkIndex: Int): ByteArray? {
        return jni.get(jobId, chunkIndex)
    }
    
    fun getAllChunks(jobId: String): List<ByteArray> {
        val chunkIndices = jni.getChunkIndices(jobId)
        return chunkIndices.mapNotNull { get(jobId, it) }
    }
    
    fun delete(jobId: String, chunkIndex: Int): Boolean {
        return jni.delete(jobId, chunkIndex)
    }
    
    fun deleteJob(jobId: String): Boolean {
        return jni.deleteJob(jobId)
    }
    
    fun snapshot() {
        jni.snapshot()
    }
    
    fun restore() {
        jni.restore()
    }
    
    fun emergencyCheckpoint() {
        jni.emergencyCheckpoint()
    }
    
    fun getStats(): StoreStats {
        return jni.getStats()
    }
    
    private fun computeChecksum(data: ByteArray): ByteArray {
        val md = java.security.MessageDigest.getInstance("SHA-256")
        return md.digest(data)
    }
    
    companion object {
        fun create(context: Context, maxSizeBytes: Long): RAMObjectStore {
            return RAMObjectStore(context, maxSizeBytes)
        }
    }
}

data class StoreStats(
    val currentSizeBytes: Long,
    val maxSizeBytes: Long,
    val chunkCount: Int,
    val hitRate: Double
)

