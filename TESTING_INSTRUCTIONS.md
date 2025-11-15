# Project Hydra — Testing Instructions

This document provides comprehensive testing instructions for Project Hydra, including unit tests, integration tests, and end-to-end scenarios.

---

## Test Structure

```
tests/
├── integration/
│   ├── quic_connectivity_test.kt
│   ├── inference_pipeline_test.kt
│   └── crash_recovery_test.kt
└── load_tests/
    ├── throughput_test.kt
    └── stress_test.kt
```

---

## Unit Tests

### Android

#### RAM Store Tests

```kotlin
// android/app/src/test/java/com/hydra/ramstore/RAMStoreTest.kt
@Test
fun testPutAndGet() {
    val store = RAMObjectStore.create(context, 1024 * 1024)
    val data = "test data".toByteArray()
    assertTrue(store.put("job1", 0, data))
    val retrieved = store.get("job1", 0)
    assertArrayEquals(data, retrieved)
}
```

#### Job Ledger Tests

```kotlin
// android/app/src/test/java/com/hydra/job/JobLedgerTest.kt
@Test
fun testJobCreation() {
    val ledger = JobLedger.create(context)
    ledger.createJob("job1", 1, 10, "{}")
    val status = ledger.getJobStatus("job1")
    assertNotNull(status)
    assertEquals(0, status?.completedChunks)
}
```

### iOS

#### Network Manager Tests

```swift
// ios/HydraTests/NetworkManagerTests.swift
func testConnection() async {
    let manager = NetworkManager()
    manager.connect(ip: "127.0.0.1", port: 4433, token: "test", deviceId: "test")
    XCTAssertTrue(manager.isConnected)
}
```

---

## Integration Tests

### QUIC Connectivity Test

**Purpose:** Verify QUIC connection between iPhone and Samsung

**Steps:**
1. Start Android server on Samsung
2. Launch iOS app on iPhone
3. Scan QR code to pair
4. Verify connection established
5. Send test heartbeat
6. Verify response received

**Expected Result:** Connection successful, heartbeat round-trip < 100ms

### Inference Pipeline Test

**Purpose:** Test end-to-end inference flow

**Steps:**
1. Pair devices
2. Capture image on iPhone
3. Submit job
4. Upload chunks
5. Wait for inference result
6. Verify result format

**Expected Result:** Job completes successfully, result returned within 5 seconds

### Crash Recovery Test

**Purpose:** Verify system recovers from reboot

**Steps:**
1. Start job submission
2. Upload 5/10 chunks
3. Reboot Samsung device
4. Wait for service to restart
5. Verify job ledger restored
6. Verify RAM snapshot loaded
7. Resend remaining chunks
8. Verify job completes

**Expected Result:** Job resumes from chunk 5, completes successfully

---

## Load Tests

### Throughput Test

**Purpose:** Measure QUIC throughput

**Test Script:**
```kotlin
// android/app/src/androidTest/java/com/hydra/load/ThroughputTest.kt
@Test
fun testThroughput() {
    val startTime = System.currentTimeMillis()
    var bytesSent = 0L
    
    repeat(100) { i ->
        val chunk = ByteArray(64 * 1024) // 64KB
        quicServer.handleChunk("test-job", i, chunk)
        bytesSent += chunk.size
    }
    
    val duration = System.currentTimeMillis() - startTime
    val throughput = (bytesSent * 1000) / duration // bytes per second
    
    assertTrue(throughput > 500 * 1024 * 1024) // > 500 MB/s
}
```

**Expected Result:** Throughput > 500 MB/s on local network

### Stress Test

**Purpose:** Test system under high load

**Steps:**
1. Submit 100 concurrent jobs
2. Monitor RAM usage
3. Monitor CPU temperature
4. Verify all jobs complete
5. Check for memory leaks

**Expected Result:** All jobs complete, no crashes, memory stable

---

## Battery Tests

### Battery Guard Test

**Purpose:** Verify battery-aware scheduling

**Steps:**
1. Set battery level to 14% (simulated)
2. Attempt to submit job
3. Verify job rejected
4. Set battery to 11%
5. Verify inference paused
6. Set battery to 9%
7. Verify emergency shutdown

**Expected Result:** Jobs rejected/paused at correct thresholds

---

## Thermal Tests

### Thermal Throttling Test

**Purpose:** Verify thermal management

**Steps:**
1. Run intensive inference workload
2. Monitor CPU temperature
3. Verify throttling activates at 70°C
4. Verify batch size reduced
5. Verify system stabilizes

**Expected Result:** System throttles gracefully, no crashes

---

## Network Resilience Tests

### Connection Migration Test

**Purpose:** Test QUIC connection migration

**Steps:**
1. Establish connection on WiFi
2. Switch to cellular
3. Verify connection migrates
4. Continue job submission
5. Verify no data loss

**Expected Result:** Connection migrates seamlessly

### Network Interruption Test

**Purpose:** Test recovery from network loss

**Steps:**
1. Start job submission
2. Disable network mid-transfer
3. Wait 10 seconds
4. Re-enable network
5. Verify reconnection
6. Verify job resumes

**Expected Result:** Reconnects automatically, job resumes

---

## End-to-End Scenarios

### Scenario 1: Normal Operation

1. Pair devices
2. Capture RAW image
3. Submit for inference
4. Receive results
5. Display in UI

**Expected:** Complete flow works smoothly

### Scenario 2: Reboot Recovery

1. Submit job with 10 chunks
2. Upload 7 chunks
3. Reboot Samsung
4. Wait for recovery
5. Verify job resumes
6. Complete remaining chunks
7. Receive results

**Expected:** Job completes after recovery

### Scenario 3: Battery Depletion

1. Start multiple jobs
2. Battery drops to 15%
3. Verify new jobs rejected
4. Battery drops to 12%
5. Verify inference paused
6. Battery drops to 10%
7. Verify emergency shutdown
8. Verify checkpoints saved

**Expected:** Graceful degradation, data preserved

---

## Performance Benchmarks

### Target Metrics

- **QUIC Throughput:** > 500 MB/s (local network)
- **Inference Latency:** < 100ms per image
- **End-to-End Latency:** < 150ms (capture to result)
- **Recovery Time:** < 5 seconds (boot to ready)
- **Job Completion Rate:** 100% (with retries)

### Measurement Tools

**Android:**
```bash
# Monitor network
adb shell dumpsys netstats

# Monitor CPU
adb shell top

# Monitor memory
adb shell dumpsys meminfo com.hydra
```

**iOS:**
- Use Instruments for profiling
- Monitor network in Xcode debugger

---

## Automated Testing

### Android

```bash
# Run all unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Run specific test
./gradlew test --tests "com.hydra.ramstore.RAMStoreTest"
```

### iOS

```bash
# Run tests in Xcode
# Product → Test (⌘U)

# Or via command line
xcodebuild test -scheme Hydra -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
      - name: Build Rust
        run: cd android/rust && cargo build --release
      - name: Run Tests
        run: ./gradlew test

  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: xcodebuild test -scheme Hydra
```

---

## Test Data

### Sample Images

Place test images in:
- Android: `android/app/src/androidTest/assets/`
- iOS: `ios/HydraTests/Resources/`

### Mock Data

Use mock data generators for:
- Large files (for chunking tests)
- Network conditions (for resilience tests)
- Battery levels (for battery tests)

---

## Reporting Issues

When reporting test failures, include:
1. Test name and scenario
2. Device information (model, OS version)
3. Logs (Android: `adb logcat`, iOS: Xcode console)
4. Steps to reproduce
5. Expected vs actual behavior

---

**Last Updated:** 2024  
**Version:** 1.0

