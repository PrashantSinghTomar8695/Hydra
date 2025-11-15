# Add project specific ProGuard rules here.
-keep class com.hydra.** { *; }
-keep class com.hydra.jni.** { *; }
-dontwarn com.hydra.**

# Keep protobuf
-keep class com.google.protobuf.** { *; }

# Keep gRPC
-keep class io.grpc.** { *; }

# Keep ONNX Runtime
-keep class ai.onnxruntime.** { *; }

