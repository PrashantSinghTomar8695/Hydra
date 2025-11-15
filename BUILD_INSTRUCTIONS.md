# Project Hydra — Build Instructions

This document provides comprehensive build instructions for both Android and iOS components of Project Hydra.

---

## Prerequisites

### Android Development

1. **Android Studio** (Arctic Fox or later)
2. **Android NDK** (r23 or later)
3. **Rust Toolchain** (1.70+)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup target add aarch64-linux-android armv7-linux-androideabi
   ```
4. **Cargo NDK** (for cross-compilation)
   ```bash
   cargo install cargo-ndk
   ```
5. **Protobuf Compiler** (protoc)
   ```bash
   # On Linux/WSL
   sudo apt-get install protobuf-compiler
   ```

### iOS Development

1. **Xcode** (14.0 or later)
2. **Swift** (5.7+)
3. **CocoaPods** (optional, for dependencies)
   ```bash
   sudo gem install cocoapods
   ```
4. **Protobuf Compiler** (protoc)
   ```bash
   brew install protobuf
   ```

---

## Building Android Server

### Step 1: Generate Protobuf Code

```bash
cd android
mkdir -p app/src/main/java/com/hydra/proto

# Generate Java code from protobuf
protoc --java_out=app/src/main/java/com/hydra/proto \
    --proto_path=../shared/proto \
    ../shared/proto/hydra.proto
```

### Step 2: Build Rust Library

```bash
cd android/rust

# Build for ARM64
cargo ndk -t arm64-v8a build --release

# Build for ARMv7
cargo ndk -t armeabi-v7a build --release

# Copy libraries to Android project
cp target/aarch64-linux-android/release/libramstore.so \
   ../app/src/main/jniLibs/arm64-v8a/
cp target/armv7-linux-androideabi/release/libramstore.so \
   ../app/src/main/jniLibs/armeabi-v7a/
```

### Step 3: Build Android APK

1. Open `android/` folder in Android Studio
2. Sync Gradle files
3. Build → Build Bundle(s) / APK(s) → Build APK(s)
4. APK will be generated at `app/build/outputs/apk/debug/app-debug.apk`

### Step 4: Install on Device

```bash
# Via ADB
adb install app/build/outputs/apk/debug/app-debug.apk

# Or use Android Studio's Run button
```

---

## Building iOS Client

### Step 1: Generate Protobuf Code

```bash
cd ios

# Install Swift Protobuf plugin
swift package init --type executable

# Generate Swift code from protobuf
protoc --swift_out=Hydra/Models \
    --proto_path=../shared/proto \
    ../shared/proto/hydra.proto
```

### Step 2: Open in Xcode

1. Open `ios/Hydra.xcodeproj` in Xcode
2. Select target device (iPhone 17 Pro simulator or physical device)
3. Product → Build (⌘B)
4. Product → Run (⌘R)

### Step 3: Configure Signing

1. Select project in Xcode
2. Go to "Signing & Capabilities"
3. Select your development team
4. Xcode will automatically manage certificates

---

## Building Rust Components

### Android (JNI)

```bash
cd android/rust

# Install Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi

# Build
cargo ndk -t arm64-v8a build --release
cargo ndk -t armeabi-v7a build --release
```

### Shared Constants (Optional)

The shared constants in `shared/constants/` are Rust files. They can be compiled as a library if needed:

```bash
cd shared/constants
cargo build --release
```

---

## Dependencies

### Android (Gradle)

Dependencies are managed in `android/app/build.gradle`:

- **QUIC:** `com.microsoft.msquic:msquic:2.2.0`
- **WebRTC:** `org.webrtc:google-webrtc:1.0.32006`
- **gRPC:** `io.grpc:grpc-*:1.58.0`
- **ONNX Runtime:** `com.microsoft.onnxruntime:onnxruntime-android:1.16.0`
- **Room:** `androidx.room:room-*:2.6.0`

### iOS (Swift Package Manager)

Dependencies should be added to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0"),
    // Add msquic/quiche Swift bindings if available
]
```

---

## ONNX Model Setup

### Android

1. Place ONNX model file in `android/app/src/main/assets/model.onnx`
2. Model will be loaded automatically by `InferenceEngine`

### iOS

1. Add ONNX model to Xcode project
2. Load using CoreML or ONNX Runtime Mobile (if available for iOS)

---

## Pairing Setup

### Step 1: Start Android Server

1. Launch Hydra app on Samsung S25
2. Grant necessary permissions (camera, storage, network)
3. App will display QR code for pairing

### Step 2: Pair iPhone

1. Launch Hydra app on iPhone 17 Pro
2. Tap "Pair with Samsung"
3. Scan QR code displayed on Samsung
4. Connection will be established automatically

---

## Testing QUIC Connectivity

### Android Side

```bash
# Check if server is listening
adb shell netstat -an | grep 4433

# View logs
adb logcat | grep QuicServer
```

### iOS Side

```swift
// In Xcode console, check connection status
// NetworkManager will log connection events
```

---

## Troubleshooting

### Android Build Issues

**Problem:** Rust library not found
- **Solution:** Ensure `libramstore.so` is in `app/src/main/jniLibs/<abi>/`

**Problem:** Protobuf classes not found
- **Solution:** Run protoc generation step (Step 1)

**Problem:** ONNX Runtime errors
- **Solution:** Ensure model file exists in `assets/` folder

### iOS Build Issues

**Problem:** Camera permission denied
- **Solution:** Add `NSCameraUsageDescription` to Info.plist (already added)

**Problem:** QUIC connection fails
- **Solution:** Ensure both devices are on same network
- Check firewall settings

### Rust Build Issues

**Problem:** `cargo-ndk` not found
- **Solution:** `cargo install cargo-ndk`

**Problem:** Android target not installed
- **Solution:** `rustup target add aarch64-linux-android`

---

## Production Build

### Android

1. Generate signing key:
   ```bash
   keytool -genkey -v -keystore hydra-release.keystore \
       -alias hydra -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Configure `android/app/build.gradle`:
   ```gradle
   signingConfigs {
       release {
           storeFile file('hydra-release.keystore')
           storePassword 'your-password'
           keyAlias 'hydra'
           keyPassword 'your-password'
       }
   }
   ```

3. Build release APK:
   ```bash
   ./gradlew assembleRelease
   ```

### iOS

1. Configure code signing in Xcode
2. Product → Archive
3. Distribute App

---

## Performance Optimization

### Android

- Enable ProGuard/R8 for release builds
- Use release Rust build (`--release`)
- Optimize ONNX model (quantization)

### iOS

- Enable compiler optimizations (`-O`)
- Use release configuration
- Profile with Instruments

---

## Next Steps

1. **Integration Testing:** Run end-to-end tests (see `TESTING_INSTRUCTIONS.md`)
2. **Performance Benchmarking:** Measure throughput and latency
3. **Deployment:** Follow production build steps above

---

**Last Updated:** 2024  
**Version:** 1.0

