# Project Hydra — Protocol Specifications

**Version:** 1.0

---

## Table of Contents

1. [Protobuf Schemas](#protobuf-schemas)
2. [gRPC Service Definitions](#grpc-service-definitions)
3. [QUIC Stream Definitions](#quic-stream-definitions)
4. [WebRTC DataChannel Protocol](#webrtc-datachannel-protocol)
5. [mTLS Handshake](#mtls-handshake)
6. [Pairing Protocol](#pairing-protocol)
7. [Error Codes](#error-codes)
8. [Retry Logic](#retry-logic)

---

## Protobuf Schemas

### Core Messages

See `shared/proto/hydra.proto` for complete definitions.

**Key Messages:**
- `JobRequest`: Job initiation
- `ChunkUpload`: Data chunk transfer
- `JobResponse`: Inference results
- `Heartbeat`: Health status
- `RecoveryState`: Post-reboot sync
- `BatteryAlert`: Low battery warning

### Service Definitions

```protobuf
service HydraService {
  rpc SubmitJob(JobRequest) returns (JobAck);
  rpc UploadChunk(ChunkUpload) returns (ChunkAck);
  rpc GetJobStatus(JobStatusRequest) returns (JobStatus);
  rpc StreamHeartbeat(stream Heartbeat) returns (stream Heartbeat);
}
```

---

## gRPC Service Definitions

### HydraService

**SubmitJob:**
- Input: `JobRequest`
- Output: `JobAck`
- Purpose: Initiate new job
- Error: Returns error if battery < 15%

**UploadChunk:**
- Input: `ChunkUpload`
- Output: `ChunkAck`
- Purpose: Transfer data chunk
- Error: Returns error if chunk invalid

**GetJobStatus:**
- Input: `JobStatusRequest`
- Output: `JobStatus`
- Purpose: Query job progress
- Error: Returns error if job not found

**StreamHeartbeat:**
- Input: Bidirectional stream of `Heartbeat`
- Output: Bidirectional stream of `Heartbeat`
- Purpose: Health monitoring
- Frequency: Every 500ms

---

## QUIC Stream Definitions

### Stream Types

**Stream 0 (Control):**
- Heartbeat messages
- Job control
- Pairing

**Streams 1-N (Data):**
- Chunk uploads
- Inference results
- One stream per job (optional parallel)

### Stream Lifecycle

1. **Creation:** Client opens stream
2. **Data Transfer:** Chunks sent sequentially
3. **Completion:** Stream closed gracefully
4. **Error:** Stream reset on failure

### Stream Multiplexing

- Up to 100 concurrent streams
- Each stream independent
- Automatic flow control

---

## WebRTC DataChannel Protocol

### Frame Format

```
[4 bytes: Length (big-endian)]
[4 bytes: Sequence Number (big-endian)]
[4 bytes: Total Chunks (big-endian)]
[4 bytes: Chunk Index (big-endian)]
[32 bytes: SHA-256 Checksum]
[Payload: Variable length]
```

**Total Frame Size:** 48 bytes header + payload

### Chunk Reassembly

1. Receive chunks in any order
2. Buffer by sequence number
3. Validate checksums
4. Reassemble when all chunks received
5. Deliver to application

### Error Handling

- Missing chunks: Request retransmission
- Invalid checksum: Discard, request retry
- Timeout: Abort transfer

---

## mTLS Handshake

### Certificate Generation

**Samsung (Server):**
- Generate self-signed CA
- Generate server certificate
- Store in Android Keystore

**iPhone (Client):**
- Generate client certificate
- Store in iOS Keychain
- Pin server certificate

### Handshake Flow

1. Client sends ClientHello
2. Server responds with ServerHello + certificate
3. Client validates server certificate (pinning)
4. Client sends client certificate
5. Server validates client certificate
6. Key exchange (ECDHE)
7. Handshake complete

### Perfect Forward Secrecy

- ECDHE key exchange
- Ephemeral keys
- Keys rotated per session

---

## Pairing Protocol

### QR Code Format

**Structure:**
```
HYDRA://pair?token=<256-bit-hex>&device_id=<device-id>&port=<quic-port>
```

**Example:**
```
HYDRA://pair?token=a1b2c3d4e5f6...&device_id=S25-ABC123&port=4433
```

### Pairing Flow

1. Samsung generates ephemeral token (256-bit random)
2. Samsung displays QR code
3. iPhone scans QR code
4. iPhone extracts token, device_id, port
5. iPhone connects to Samsung via QUIC
6. iPhone sends `PairingRequest` with token
7. Samsung validates token
8. Samsung responds with `PairingResponse` (session token)
9. Session established

### Token Lifecycle

- **Ephemeral token:** Valid for 5 minutes
- **Session token:** Valid for 24 hours
- **Rotation:** Automatic on disconnect

---

## Error Codes

### Error Code Enum

```protobuf
enum ErrorCode {
  ERROR_UNKNOWN = 0;
  ERROR_NETWORK_TIMEOUT = 1;
  ERROR_INVALID_JOB_ID = 2;
  ERROR_INVALID_CHUNK = 3;
  ERROR_BATTERY_LOW = 4;
  ERROR_THERMAL_THROTTLE = 5;
  ERROR_INFERENCE_FAILED = 6;
  ERROR_STORAGE_FULL = 7;
  ERROR_AUTHENTICATION_FAILED = 8;
  ERROR_STREAM_RESET = 9;
  ERROR_DEVICE_OFFLINE = 10;
}
```

### Error Response Format

```protobuf
message ErrorResponse {
  ErrorCode code = 1;
  string message = 2;
  int64 timestamp = 3;
  string job_id = 4; // If applicable
}
```

---

## Retry Logic

### Exponential Backoff

**Strategy:**
- Initial delay: 1 second
- Max delay: 30 seconds
- Backoff multiplier: 2x
- Max retries: 5

**Example:**
```
Attempt 1: Wait 1s
Attempt 2: Wait 2s
Attempt 3: Wait 4s
Attempt 4: Wait 8s
Attempt 5: Wait 16s
Attempt 6: Wait 30s (capped)
```

### Circuit Breaker

**States:**
- **Closed:** Normal operation
- **Open:** Failures exceed threshold (10 failures)
- **Half-Open:** Testing recovery

**Thresholds:**
- Open after 10 consecutive failures
- Half-open after 60 seconds
- Close after 3 successful requests

### Retryable vs Non-Retryable

**Retryable:**
- Network timeout
- Connection refused
- Stream reset
- Temporary server error (5xx)

**Non-Retryable:**
- Authentication failure
- Invalid job ID
- Malformed request
- Battery critical (wait for recovery)

---

## Message Flow Examples

### Job Submission

```
iPhone → Samsung: JobRequest { job_id: "abc123", type: INFERENCE, total_chunks: 10 }
Samsung → iPhone: JobAck { job_id: "abc123", status: ACCEPTED }

iPhone → Samsung: ChunkUpload { job_id: "abc123", chunk_index: 0, data: [...] }
Samsung → iPhone: ChunkAck { job_id: "abc123", chunk_index: 0, status: OK }

... (repeat for all chunks) ...

Samsung → iPhone: JobResponse { job_id: "abc123", result: {...}, status_code: 200 }
```

### Heartbeat

```
iPhone → Samsung: Heartbeat { battery_percent: 85.0, ... }
Samsung → iPhone: Heartbeat { battery_percent: 78.0, cpu_temp: 45.0, ... }

... (every 500ms) ...
```

### Recovery

```
Samsung [Reboot]
Samsung [Load Ledger]
Samsung [Load RAM Snapshot]

iPhone → Samsung: [Reconnect]
Samsung → iPhone: RecoveryState { incomplete_jobs: ["abc123"], ... }

iPhone → Samsung: JobStatusRequest { job_id: "abc123" }
Samsung → iPhone: JobStatus { job_id: "abc123", completed_chunks: 7, total_chunks: 10 }

iPhone → Samsung: ChunkUpload { job_id: "abc123", chunk_index: 7, ... }
... (resume from chunk 7) ...
```

---

**Document Version:** 1.0  
**Last Updated:** 2024

