package com.hydra.battery

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

class BatteryMonitor(
    private val context: Context,
    private val onBatteryChange: (Float) -> Unit
) {
    private var receiver: BroadcastReceiver? = null
    private var monitoring = false
    
    fun startMonitoring() {
        if (monitoring) return
        
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                    val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    val batteryPercent = (level * 100.0f / scale)
                    onBatteryChange(batteryPercent)
                }
            }
        }
        
        context.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        monitoring = true
    }
    
    fun stopMonitoring() {
        receiver?.let {
            context.unregisterReceiver(it)
            receiver = null
        }
        monitoring = false
    }
    
    fun getCurrentBatteryLevel(): Float {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return level.toFloat()
    }
}

