package com.hydra

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.hydra.service.HydraService
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Start foreground service
        val serviceIntent = Intent(this, HydraService::class.java)
        startForegroundService(serviceIntent)
        
        // Open pairing screen
        lifecycleScope.launch {
            val pairingIntent = Intent(this@MainActivity, PairingActivity::class.java)
            startActivity(pairingIntent)
        }
    }
}

