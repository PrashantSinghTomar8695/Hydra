package com.hydra

import android.os.Bundle
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import com.hydra.crypto.CryptoUtils
import com.hydra.network.QuicServer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.net.InetAddress

class PairingActivity : AppCompatActivity() {
    private lateinit var qrImageView: ImageView
    private lateinit var statusText: TextView
    private lateinit var deviceIdText: TextView
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_pairing)
        
        qrImageView = findViewById(R.id.qr_code_image)
        statusText = findViewById(R.id.status_text)
        deviceIdText = findViewById(R.id.device_id_text)
        
        generatePairingQR()
    }
    
    private fun generatePairingQR() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Generate ephemeral token
                val token = CryptoUtils.generatePairingToken()
                val tokenHex = token.joinToString("") { "%02x".format(it) }
                
                // Get device ID
                val deviceId = android.provider.Settings.Secure.getString(
                    contentResolver,
                    android.provider.Settings.Secure.ANDROID_ID
                )
                
                // Get local IP
                val localIp = getLocalIpAddress()
                val port = QuicServer.DEFAULT_PORT
                
                // Build QR code URL
                val qrUrl = "HYDRA://pair?token=$tokenHex&device_id=$deviceId&port=$port&ip=$localIp"
                
                // Generate QR code bitmap
                val qrBitmap = generateQRCodeBitmap(qrUrl, 512, 512)
                
                runOnUiThread {
                    qrImageView.setImageBitmap(qrBitmap)
                    deviceIdText.text = "Device ID: $deviceId"
                    statusText.text = "Waiting for iPhone to scan QR code..."
                }
            } catch (e: Exception) {
                runOnUiThread {
                    statusText.text = "Error: ${e.message}"
                }
            }
        }
    }
    
    private fun generateQRCodeBitmap(content: String, width: Int, height: Int): android.graphics.Bitmap {
        val hints = hashMapOf<EncodeHintType, Any>().apply {
            put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.H)
            put(EncodeHintType.CHARACTER_SET, "UTF-8")
        }
        
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(content, BarcodeFormat.QR_CODE, width, height, hints)
        
        val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.RGB_565)
        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
            }
        }
        
        return bitmap
    }
    
    private fun getLocalIpAddress(): String {
        try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        return address.hostAddress ?: "127.0.0.1"
                    }
                }
            }
        } catch (e: Exception) {
            // Fallback
        }
        return "127.0.0.1"
    }
}

