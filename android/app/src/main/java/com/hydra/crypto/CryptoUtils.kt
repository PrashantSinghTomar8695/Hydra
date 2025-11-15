package com.hydra.crypto

import java.security.MessageDigest
import java.security.SecureRandom

object CryptoUtils {
    private val random = SecureRandom()
    
    fun generatePairingToken(): ByteArray {
        val token = ByteArray(32) // 256 bits
        random.nextBytes(token)
        return token
    }
    
    fun generateSessionToken(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return (1..64)
            .map { chars[random.nextInt(chars.length)] }
            .joinToString("")
    }
    
    fun computeSHA256(data: ByteArray): ByteArray {
        val md = MessageDigest.getInstance("SHA-256")
        return md.digest(data)
    }
}

