package com.hydra.job

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "jobs")
data class JobEntity(
    @PrimaryKey val jobId: String,
    val jobType: Int,
    val totalChunks: Int,
    val completedChunks: Int,
    val metadata: String,
    val timestamp: Long,
    val inferenceStarted: Boolean,
    val inferenceCompleted: Boolean,
    val lastUpdate: Long,
    val retryCount: Int = 0
)

@Entity(tableName = "chunks")
data class ChunkEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val jobId: String,
    val chunkIndex: Int,
    val checksum: String,
    val stored: Boolean,
    val timestamp: Long
)

@Dao
interface JobDao {
    @Query("SELECT * FROM jobs WHERE inferenceCompleted = 0")
    fun getIncompleteJobs(): List<JobEntity>
    
    @Query("SELECT * FROM jobs WHERE jobId = :jobId")
    fun getJob(jobId: String): JobEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertJob(job: JobEntity)
    
    @Update
    fun updateJob(job: JobEntity)
    
    @Query("UPDATE jobs SET completedChunks = :count WHERE jobId = :jobId")
    fun updateChunkCount(jobId: String, count: Int)
    
    @Query("UPDATE jobs SET inferenceStarted = 1 WHERE jobId = :jobId")
    fun markInferenceStarted(jobId: String)
    
    @Query("UPDATE jobs SET inferenceCompleted = 1 WHERE jobId = :jobId")
    fun markInferenceCompleted(jobId: String)
}

@Dao
interface ChunkDao {
    @Query("SELECT * FROM chunks WHERE jobId = :jobId")
    fun getChunks(jobId: String): List<ChunkEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertChunk(chunk: ChunkEntity)
    
    @Query("SELECT COUNT(*) FROM chunks WHERE jobId = :jobId AND stored = 1")
    fun getStoredChunkCount(jobId: String): Int
}

@Database(entities = [JobEntity::class, ChunkEntity::class], version = 1)
abstract class JobLedgerDatabase : RoomDatabase() {
    abstract fun jobDao(): JobDao
    abstract fun chunkDao(): ChunkDao
}

class JobLedger private constructor(context: Context) {
    private val db = Room.databaseBuilder(
        context,
        JobLedgerDatabase::class.java,
        "ledger.db"
    ).build()
    
    private val jobDao = db.jobDao()
    private val chunkDao = db.chunkDao()
    
    fun createJob(
        jobId: String,
        jobType: Int,
        totalChunks: Int,
        metadata: String
    ) {
        val job = JobEntity(
            jobId = jobId,
            jobType = jobType,
            totalChunks = totalChunks,
            completedChunks = 0,
            metadata = metadata,
            timestamp = System.currentTimeMillis(),
            inferenceStarted = false,
            inferenceCompleted = false,
            lastUpdate = System.currentTimeMillis()
        )
        jobDao.insertJob(job)
    }
    
    fun markChunkStored(jobId: String, chunkIndex: Int, checksum: String) {
        val chunk = ChunkEntity(
            jobId = jobId,
            chunkIndex = chunkIndex,
            checksum = checksum,
            stored = true,
            timestamp = System.currentTimeMillis()
        )
        chunkDao.insertChunk(chunk)
        
        val storedCount = chunkDao.getStoredChunkCount(jobId)
        jobDao.updateChunkCount(jobId, storedCount)
    }
    
    fun getJobStatus(jobId: String): JobEntity? {
        return jobDao.getJob(jobId)
    }
    
    fun markInferenceStarted(jobId: String) {
        jobDao.markInferenceStarted(jobId)
    }
    
    fun markInferenceCompleted(jobId: String) {
        jobDao.markInferenceCompleted(jobId)
    }
    
    fun loadIncompleteJobs(): List<JobEntity> {
        return jobDao.getIncompleteJobs()
    }
    
    fun flush() {
        // Room handles transactions automatically
        // This is a no-op, but kept for API consistency
    }
    
    companion object {
        @Volatile
        private var INSTANCE: JobLedger? = null
        
        fun create(context: Context): JobLedger {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: JobLedger(context.applicationContext).also { INSTANCE = it }
            }
        }
    }
}

