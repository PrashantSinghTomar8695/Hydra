package com.hydra.ml

import android.content.Context
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.util.Log
import java.nio.FloatBuffer
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class InferenceEngine private constructor(
    private val context: Context
) {
    private var ortEnvironment: OrtEnvironment? = null
    private var ortSession: OrtSession? = null
    private var paused = false
    
    init {
        initialize()
    }
    
    private fun initialize() {
        try {
            ortEnvironment = OrtEnvironment.getEnvironment()
            
            // Load ONNX model from assets
            val modelPath = context.assets.open("model.onnx").use { input ->
                val tempFile = java.io.File(context.cacheDir, "model.onnx")
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
                tempFile.absolutePath
            }
            
            val sessionOptions = OrtSession.SessionOptions()
            sessionOptions.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
            
            // Enable NNAPI delegate
            sessionOptions.addNnapi()
            
            ortSession = ortEnvironment!!.createSession(modelPath, sessionOptions)
            Log.d(TAG, "ONNX model loaded successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize inference engine", e)
        }
    }
    
    suspend fun runInference(
        inputData: FloatArray,
        inputShape: LongArray
    ): FloatArray? = suspendCancellableCoroutine { continuation ->
        if (paused) {
            continuation.resume(null)
            return@suspendCancellableCoroutine
        }
        
        try {
            val session = ortSession ?: run {
                continuation.resume(null)
                return@suspendCancellableCoroutine
            }
            
            // Create input tensor
            val inputTensor = OnnxTensor.createTensor(
                ortEnvironment,
                FloatBuffer.wrap(inputData),
                inputShape
            )
            
            val inputs = mapOf("input" to inputTensor)
            
            // Run inference
            val outputs = session.run(inputs)
            
            // Extract output
            val outputTensor = outputs[0].value as Array<FloatArray>
            val result = outputTensor[0]
            
            inputTensor.close()
            outputs.close()
            
            continuation.resume(result)
        } catch (e: Exception) {
            Log.e(TAG, "Inference error", e)
            continuation.resume(null)
        }
    }
    
    fun pause() {
        paused = true
    }
    
    fun resume() {
        paused = false
    }
    
    fun close() {
        ortSession?.close()
        ortEnvironment?.close()
    }
    
    companion object {
        private const val TAG = "InferenceEngine"
        
        fun create(context: Context): InferenceEngine {
            return InferenceEngine(context)
        }
    }
}

