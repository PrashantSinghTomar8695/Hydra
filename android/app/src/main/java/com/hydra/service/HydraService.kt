package com.hydra.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import com.hydra.MainActivity
import com.hydra.R
import com.hydra.battery.BatteryMonitor
import com.hydra.job.JobLedger
import com.hydra.ml.InferenceEngine
import com.hydra.network.QuicServer
import com.hydra.ramstore.RAMObjectStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class HydraService : Service() {
    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    private lateinit var quicServer: QuicServer
    private lateinit var ramStore: RAMObjectStore
    private lateinit var jobLedger: JobLedger
    private lateinit var inferenceEngine: InferenceEngine
    private lateinit var batteryMonitor: BatteryMonitor
    
    private var wakeLock: PowerManager.WakeLock? = null
    
    inner class LocalBinder : Binder() {
        fun getService(): HydraService = this@HydraService
    }
    
    override fun onCreate() {
        super.onCreate()
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Acquire wake lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "HydraService::WakeLock").apply {
            acquire(10 * 60 * 1000L) // 10 minutes
        }
        
        // Initialize components
        serviceScope.launch {
            initializeComponents()
        }
    }
    
    private suspend fun initializeComponents() {
        // Initialize RAM store
        ramStore = RAMObjectStore.create(
            context = applicationContext,
            maxSizeBytes = 12L * 1024 * 1024 * 1024 // 12GB
        )
        
        // Restore from snapshot
        ramStore.restore()
        
        // Initialize job ledger
        jobLedger = JobLedger.create(applicationContext)
        jobLedger.loadIncompleteJobs()
        
        // Initialize inference engine
        inferenceEngine = InferenceEngine.create(applicationContext)
        
        // Initialize battery monitor
        batteryMonitor = BatteryMonitor(applicationContext) { batteryPercent ->
            handleBatteryChange(batteryPercent)
        }
        batteryMonitor.startMonitoring()
        
        // Start QUIC server
        quicServer = QuicServer(
            port = 4433,
            ramStore = ramStore,
            jobLedger = jobLedger,
            inferenceEngine = inferenceEngine,
            batteryMonitor = batteryMonitor
        )
        quicServer.start()
        
        // Start periodic tasks
        startPeriodicTasks()
    }
    
    private fun startPeriodicTasks() {
        serviceScope.launch {
            // Flush ledger every 500ms
            while (true) {
                kotlinx.coroutines.delay(500)
                jobLedger.flush()
            }
        }
        
        serviceScope.launch {
            // Create snapshot every 30 seconds
            while (true) {
                kotlinx.coroutines.delay(30000)
                ramStore.snapshot()
            }
        }
    }
    
    private fun handleBatteryChange(batteryPercent: Float) {
        when {
            batteryPercent <= 10.0f -> {
                // Emergency shutdown
                emergencyShutdown()
            }
            batteryPercent <= 12.0f -> {
                // Pause inference
                inferenceEngine.pause()
                quicServer.sendBatteryAlert(3) // Emergency level
            }
            batteryPercent <= 15.0f -> {
                // Stop accepting new jobs
                quicServer.setAcceptNewJobs(false)
                quicServer.sendBatteryAlert(1) // Low level
            }
            else -> {
                // Resume normal operation
                quicServer.setAcceptNewJobs(true)
                inferenceEngine.resume()
            }
        }
    }
    
    private fun emergencyShutdown() {
        serviceScope.launch {
            // Dump RAM to disk
            ramStore.emergencyCheckpoint()
            
            // Flush ledger
            jobLedger.flush()
            
            // Stop server
            quicServer.stop()
            
            // Stop service
            stopSelf()
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY // Restart if killed
    }
    
    override fun onBind(intent: Intent?): IBinder {
        return binder
    }
    
    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
        quicServer.stop()
        batteryMonitor.stopMonitoring()
        ramStore.snapshot() // Final snapshot
        jobLedger.flush() // Final flush
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Hydra Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Hydra Service")
            .setContentText("Edge compute node active")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    companion object {
        private const val CHANNEL_ID = "hydra_service_channel"
        private const val NOTIFICATION_ID = 1
    }
}

