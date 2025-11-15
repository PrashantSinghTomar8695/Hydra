# Project Hydra — Cross-Device Edge Supercomputer
## Technical Architecture Document

**Version:** 1.0  
**Date:** 2024  
**Author:** CTO & Principal Architect

---

## Abstract

Project Hydra is a distributed edge computing system that transforms a Samsung S25 (Android) into a high-performance compute node for an iPhone 17 Pro (iOS). The system enables real-time RAW image processing, ML inference, and distributed task execution over QUIC/WebRTC protocols with zero-copy data transfer, persistent job recovery, and battery-aware scheduling.

**Key Innovation:** The Samsung S25 acts as a "supernode" providing:
- 12GB+ RAM object store with LRU eviction
- ONNX Runtime Mobile with NNAPI/Qualcomm GPU acceleration
- Persistent job ledger with crash recovery
- QUIC-based RPC with WebRTC fallback
- Battery-aware task scheduling

---

## Executive Summary

### Problem Statement

Modern mobile devices face limitations:
- **iPhone 17 Pro:** Excellent camera, limited RAM for large RAW processing
- **Samsung S25:** Powerful GPU/NPU, abundant RAM, underutilized compute

### Solution

Hydra creates a distributed system where:
1. iPhone captures RAW images and orchestrates tasks
2. Samsung receives data chunks, stores in RAM, processes via ML
3. Results stream back to iPhone over QUIC with sub-100ms latency
4. System survives reboots, network changes, battery depletion

### Key Metrics

- **Throughput:** 500+ MB/s over QUIC
- **Latency:** <100ms inference-to-result
- **Resilience:** 100% job recovery after reboot
- **Battery:** Graceful degradation below 15%

---

## End-to-End Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    iPhone 17 Pro (iOS)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ RAW Capture  │  │ Orchestrator │  │ QUIC Client  │      │
│  │   Pipeline   │→ │   Scheduler  │→ │   + WebRTC   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          │         QUIC Streams / WebRTC       │
          │         (mTLS, Token Auth)          │
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼──────────────┐
│         │                  │                  │              │
│  ┌──────▼──────┐  ┌───────▼───────┐  ┌──────▼──────┐      │
│  │ QUIC Server │  │  RAM Object   │  │ ML Inference │      │
│  │  + WebRTC   │→ │     Store     │→ │   (ONNX)     │      │
│  └──────┬──────┘  └───────┬───────┘  └──────┬──────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼──────┐      │
│  │         Job Ledger (SQLite + Rust)                │      │
│  │  - Job State Tracking                             │      │
│  │  - Chunk Progress                                 │      │
│  │  - Crash Recovery                                 │      │
│  └───────────────────────────────────────────────────┘      │
│                    Samsung S25 (Android)                     │
└─────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. iPhone 17 Pro Components

**A. RAW Capture Pipeline**
- AVFoundation RAW capture
- Zero-copy buffer management
- Chunked streaming (64KB chunks)
- Metadata extraction (EXIF, timestamps)

**B. Task Orchestrator**
- Priority queue (FIFO + priority)
- Retry logic with exponential backoff
- Batch aggregation
- Job deduplication

**C. QUIC Client**
- msquic/quiche integration
- Stream multiplexing (up to 100 streams)
- Automatic reconnection
- Certificate pinning

**D. WebRTC Fallback**
- DataChannel for large blobs
- Custom framing protocol
- Chunk reassembly

**E. UI Layer**
- SwiftUI views
- Real-time metrics
- Pairing QR scanner
- Result visualization

#### 2. Samsung S25 Components

**A. QUIC Server**
- Multi-stream handling
- Connection migration
- Stream resume
- mTLS termination

**B. RAM Object Store**
- 12GB+ capacity
- LRU eviction
- TTL-based expiration
- Chunked storage (variable chunk size)
- Thread-safe locking (RwLock)
- Snapshot/restore for crash recovery

**C. ML Inference Module**
- ONNX Runtime Mobile
- NNAPI delegate (Qualcomm GPU)
- Model loading/caching
- Batch inference
- Partial result support

**D. Job Ledger**
- SQLite database
- Rust-backed with JNI
- Flush every 500ms
- Recovery on boot
- State synchronization

**E. File Storage**
- Android scoped storage
- Compressed checkpoints
- Blob management
- Cleanup policies

**F. Foreground Service**
- Background execution
- WorkManager integration
- Auto-restart on kill
- Battery monitoring

---

## Networking Model

### Primary: QUIC RPC

**Protocol Stack:**
```
Application Layer (gRPC)
    ↓
Protobuf Serialization
    ↓
QUIC Streams (msquic/quiche)
    ↓
UDP/IP
```

**Stream Types:**
- **Control Stream (0):** Heartbeat, job control, pairing
- **Data Streams (1-N):** Chunked uploads, inference results
- **Bidirectional:** RPC requests/responses

**Connection Flow:**
1. Pairing via QR code (ephemeral token exchange)
2. mTLS handshake (x.509 certificates)
3. Token-based session establishment
4. Stream creation for each job
5. Heartbeat every 500ms

### Fallback: WebRTC DataChannel

**When Used:**
- QUIC connection fails
- Large blob transfers (>10MB)
- Network path MTU issues

**Framing Protocol:**
```
[4 bytes: Length][4 bytes: Sequence][4 bytes: Total Chunks][Payload]
```

**Reassembly:**
- Buffer chunks by sequence number
- Validate checksums
- Reassemble on completion

---

## Protocol Design

### Application Layer

**Message Types:**
- `JobRequest`: Upload job with metadata
- `JobResponse`: Inference results
- `ChunkUpload`: Data chunk with checksum
- `Heartbeat`: Health status
- `RecoveryState`: Post-reboot sync
- `BatteryAlert`: Low battery warning

### Protobuf Schema (See `shared/proto/hydra.proto`)

```protobuf
syntax = "proto3";

package hydra;

message JobRequest {
  string job_id = 1;
  JobType type = 2;
  int32 total_chunks = 3;
  bytes metadata = 4;
  int64 timestamp = 5;
}

message ChunkUpload {
  string job_id = 1;
  int32 chunk_index = 2;
  int32 total_chunks = 3;
  bytes data = 4;
  bytes checksum = 5;
}

message JobResponse {
  string job_id = 1;
  InferenceResult result = 2;
  bytes output_data = 3;
  int32 status_code = 4;
}

message Heartbeat {
  float battery_percent = 1;
  float cpu_temp = 2;
  int64 ram_usage_bytes = 3;
  bool thermal_throttling = 4;
  int32 inference_queue_length = 5;
}
```

### Message Framing

**QUIC Stream:**
- No framing needed (QUIC handles it)
- Protobuf messages are length-prefixed

**WebRTC DataChannel:**
- Custom frame header (16 bytes)
- Payload follows

---

## Sequence Diagrams

### Normal Flow: Capture → Offload → Inference → Return

```
iPhone                    Samsung
  │                          │
  │─── RAW Capture ──────────│
  │                          │
  │─── JobRequest ──────────>│
  │                          │
  │─── ChunkUpload[0] ──────>│
  │─── ChunkUpload[1] ──────>│
  │─── ChunkUpload[N] ──────>│
  │                          │
  │                          │─── Store in RAM ──┐
  │                          │                  │
  │                          │<─── ONNX Inference
  │                          │                  │
  │<─── JobResponse ─────────│                  │
  │                          │                  │
  │─── Display Results ──────│                  │
```

### Recovery Flow: Reboot → Restore → Resume

```
iPhone                    Samsung
  │                          │
  │─── Heartbeat ───────────>│
  │<─── No Response ────────│ (Timeout)
  │                          │
  │ [Detect Disconnect]      │
  │                          │
  │ [Wait 3s]                │
  │                          │
  │                          │ [Reboot]
  │                          │
  │                          │ [Load Ledger]
  │                          │ [Load RAM Snapshot]
  │                          │
  │─── Reconnect ───────────>│
  │<─── RecoveryState ───────│
  │                          │
  │─── Resend Missing ──────>│
  │                          │
  │<─── JobResponse ─────────│
```

---

## RAM Object Store Design

### Architecture

```
┌─────────────────────────────────────────┐
│         RAM Object Store                │
│  ┌───────────────────────────────────┐  │
│  │      LRU Cache (HashMap)          │  │
│  │  Key: job_id + chunk_index        │  │
│  │  Value: ChunkData                 │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │      TTL Manager                  │  │
│  │  - Expiration tracking            │  │
│  │  - Background cleanup             │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │      Chunk Manager                │  │
│  │  - Variable chunk size            │  │
│  │  - Reassembly logic               │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │      Snapshot Manager             │  │
│  │  - Periodic snapshots              │  │
│  │  - Journal (WAL)                  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Data Structures

**ChunkData:**
```rust
struct ChunkData {
    job_id: String,
    chunk_index: u32,
    data: Vec<u8>,
    checksum: [u8; 32],
    timestamp: i64,
    ttl: i64,
    access_count: u32,
}
```

**LRU Implementation:**
- HashMap for O(1) lookup
- Doubly-linked list for LRU ordering
- RwLock for thread safety

**Eviction Policy:**
1. Check TTL expiration
2. If full, evict least recently used
3. Write evicted chunks to disk (if not processed)
4. Update ledger

### Chunking Strategy

- **Variable chunk size:** 64KB default, up to 1MB for large blobs
- **Reassembly:** Track by `job_id` + `chunk_index`
- **Validation:** SHA-256 checksum per chunk

### Locking Model

- **Read operations:** Shared lock (RwLock::read)
- **Write operations:** Exclusive lock (RwLock::write)
- **Snapshot:** Exclusive lock, atomic copy

---

## ML Inference Design

### ONNX Runtime Mobile Integration

**Model Loading:**
1. Load ONNX model from assets
2. Create InferenceSession
3. Configure NNAPI delegate
4. Cache session in memory

**Inference Flow:**
```
Input Chunks → Reassemble → Preprocess → ONNX Runtime
    ↓
NNAPI/Qualcomm GPU
    ↓
Post-process → Output Tensors → Serialize → Return
```

**Batch Processing:**
- Queue multiple jobs
- Batch when possible (same model)
- Process in parallel streams

**Partial Results:**
- Support checkpointing mid-inference
- Return partial tensors on interrupt
- Resume from checkpoint

### Performance Optimizations

- **Zero-copy:** Direct memory mapping where possible
- **GPU acceleration:** NNAPI delegate for Qualcomm
- **Model quantization:** INT8 models for speed
- **Async execution:** Non-blocking inference

---

## Error Handling

### Network Retry

**Strategy:**
- Exponential backoff: 1s, 2s, 4s, 8s, max 30s
- Max retries: 5
- Circuit breaker after 10 failures

**Retryable Errors:**
- Connection timeout
- Stream reset
- Network unreachable

**Non-retryable:**
- Authentication failure
- Invalid job ID
- Malformed data

### Partial Completion

**Handling:**
- Track completed chunks in ledger
- Resume from last chunk on reconnect
- Validate checksums on resume
- Skip duplicate chunks

---

## Power/Thermal Optimization

### Battery Guard

**Thresholds:**
- **15%:** Stop accepting new jobs
- **12%:** Pause ongoing inference
- **10%:** Dump RAM to disk, shutdown

**Actions:**
- Send `BatteryAlert` to iPhone
- Save checkpoints
- Clean shutdown of streams

### Thermal Management

**Monitoring:**
- CPU temperature via `/sys/class/thermal`
- GPU temperature
- Battery temperature

**Throttling:**
- Reduce inference batch size
- Increase delays between jobs
- Pause non-critical tasks

---

## Battery-Aware Scheduling

### iPhone Side

- Prefer WiFi over cellular
- Batch jobs when battery < 20%
- Reduce capture quality if needed

### Samsung Side

- Accept jobs only if battery > 15%
- Pause at 12%
- Emergency shutdown at 10%

---

## File System Access

### iOS Sandbox Constraints

**Limitations:**
- No direct file system access
- App container only
- No shared storage

**Mitigation:**
- Use App Group containers (if available)
- Store in Documents directory
- Use Core Data for metadata

### Android Scoped Storage

**Permissions:**
- `READ_EXTERNAL_STORAGE` (if needed)
- `WRITE_EXTERNAL_STORAGE` (deprecated, use scoped)
- App-specific directories

**Storage Locations:**
- RAM snapshots: `/data/data/com.hydra/ram_store_snapshots/`
- Job ledger: `/data/data/com.hydra/databases/ledger.db`
- Checkpoints: `/data/data/com.hydra/checkpoints/`

---

## Security Model

### Pairing

**Flow:**
1. Samsung generates ephemeral token (256-bit)
2. Display as QR code
3. iPhone scans QR
4. Token exchange over initial connection
5. Establish mTLS session

**Token Lifecycle:**
- Valid for 24 hours
- Rotate on disconnect
- Store in Keychain (iOS) / Keystore (Android)

### mTLS

**Certificates:**
- Self-signed x.509 certificates
- Device-specific keys
- Certificate pinning on iPhone

**Handshake:**
- TLS 1.3 over QUIC
- Mutual authentication
- Perfect forward secrecy

### Token Rotation

- Rotate every 24 hours
- Graceful handoff
- No service interruption

---

## Performance Design

### Zero-Copy

**Where Possible:**
- Direct memory mapping for large blobs
- Buffer reuse
- Stream-based processing

**Limitations:**
- iOS: Limited zero-copy options
- Android: JNI overhead

### Chunked Streaming

- 64KB default chunks
- Parallel upload (multiple streams)
- Reassembly on receiver

### Throughput Targets

- **QUIC:** 500+ MB/s (local network)
- **WebRTC:** 200+ MB/s (fallback)
- **Inference:** <100ms per image (typical model)

---

## Scalability

### Multi-Node Support

**Future Enhancement:**
- Mesh mode (multiple Samsung nodes)
- Load balancing
- Job distribution

**Current:**
- Single node (Samsung S25)
- Designed for extension

### Horizontal Scaling

- Add more Samsung nodes
- iPhone connects to nearest
- Automatic failover

---

## Benchmark Expectations

### Latency

- **Network:** <10ms (local WiFi)
- **Inference:** 50-100ms (typical model)
- **End-to-end:** <150ms (capture to result)

### Throughput

- **Upload:** 500 MB/s (QUIC)
- **Inference:** 10-20 images/second
- **RAM Store:** 1M+ ops/second

### Reliability

- **Uptime:** 99.9% (with recovery)
- **Job completion:** 100% (with retries)
- **Crash recovery:** <5s boot to ready

---

## Logging & Telemetry

### Structured Logging

**Format:** JSON
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "INFO",
  "component": "QUIC_SERVER",
  "message": "Stream created",
  "job_id": "abc123",
  "metrics": {
    "latency_ms": 45,
    "bytes_sent": 1024
  }
}
```

### Metrics

- Job completion rate
- Average latency
- Error rates
- Battery usage
- RAM utilization

### Telemetry Collection

- Local file storage
- Optional cloud upload (user consent)
- Privacy-preserving (no PII)

---

## Deployment Strategy

### Android

1. Build APK/AAB
2. Sign with release key
3. Install via ADB or Play Store
4. Grant necessary permissions
5. Pair with iPhone

### iOS

1. Build Xcode project
2. Sign with developer certificate
3. Install via Xcode or TestFlight
4. Grant camera permissions
5. Pair with Samsung

---

## Future Enhancements

1. **Multi-node mesh:** Multiple Samsung nodes
2. **Cloud sync:** Optional cloud backup
3. **Model marketplace:** Downloadable ONNX models
4. **Real-time video:** Stream processing
5. **Federated learning:** Collaborative model training

---

## Conclusion

Project Hydra creates a production-ready distributed edge computing system that leverages the strengths of both iPhone and Samsung devices. With robust crash recovery, battery awareness, and high-performance networking, it provides a foundation for advanced mobile computing applications.

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Status:** Production Ready

