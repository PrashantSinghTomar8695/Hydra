# Networking Design

**Components:** QUIC Server/Client, WebRTC Fallback  
**Protocols:** QUIC (msquic/quiche), WebRTC DataChannel

---

## Overview

Project Hydra uses QUIC as the primary transport protocol with WebRTC DataChannel as a fallback. Both support mTLS, stream multiplexing, and connection migration.

---

## QUIC Implementation

### Library Choice

**Primary:** msquic (Microsoft QUIC)  
**Alternative:** quiche (Cloudflare)

**Rationale:**
- msquic: Better Android support, NNAPI integration
- quiche: More control, Rust-native

**Decision:** Use msquic for Android, quiche for Rust modules (if needed)

### Connection Setup

**Server (Samsung):**
1. Bind to UDP port (default: 4433)
2. Listen for incoming connections
3. Perform mTLS handshake
4. Accept streams

**Client (iPhone):**
1. Resolve server address (from QR code)
2. Connect via QUIC
3. Perform mTLS handshake (certificate pinning)
4. Open streams

### Stream Multiplexing

**Stream Types:**
- **Stream 0:** Control (heartbeat, pairing)
- **Streams 1-N:** Data (chunks, results)

**Concurrency:**
- Up to 100 concurrent streams
- Each stream independent
- Automatic flow control

### Connection Migration

**Scenario:** Network interface changes (WiFi → Cellular)

**Process:**
1. Detect new IP address
2. Send connection migration packet
3. Update connection state
4. Resume streams transparently

**Implementation:**
- Use connection ID (CID) rotation
- Maintain connection state
- Handle NAT rebinding

---

## WebRTC Fallback

### When to Use

1. **QUIC connection fails:** After 3 retries
2. **Large blob transfer:** >10MB
3. **MTU issues:** Path MTU discovery fails
4. **Network restrictions:** QUIC blocked by firewall

### Signaling

**Current:** Direct connection (no signaling server)  
**Future:** Optional STUN/TURN for NAT traversal

**Process:**
1. iPhone initiates WebRTC connection
2. Exchange SDP (via QUIC control stream or QR)
3. Establish ICE connection
4. Open DataChannel

### DataChannel Protocol

**Frame Format:**
```
[4 bytes: Length (big-endian)]
[4 bytes: Sequence Number]
[4 bytes: Total Chunks]
[4 bytes: Chunk Index]
[32 bytes: SHA-256 Checksum]
[Payload: Variable]
```

**Reassembly:**
- Buffer chunks by sequence number
- Validate checksums
- Reassemble on completion
- Deliver to application

---

## mTLS Configuration

### Certificate Generation

**Samsung (Server):**
```bash
# Generate CA
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -key ca-key.pem -out ca-cert.pem

# Generate server cert
openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server.csr
openssl x509 -req -in server.csr -CA ca-cert.pem -CAkey ca-key.pem -out server-cert.pem
```

**iPhone (Client):**
```bash
# Generate client cert
openssl genrsa -out client-key.pem 2048
openssl req -new -key client-key.pem -out client.csr
openssl x509 -req -in client.csr -CA ca-cert.pem -CAkey ca-key.pem -out client-cert.pem
```

### Certificate Storage

**Android:**
- Store in Android Keystore
- Access via KeyStore API
- Hardware-backed (if available)

**iOS:**
- Store in Keychain
- Access via Keychain Services
- Secure Enclave (if available)

### Certificate Pinning

**iPhone Implementation:**
```swift
let serverCert = loadCertificate()
let pinnedCert = serverCert.publicKey

// In QUIC connection
connection.setCertificatePinning(pinnedCert)
```

---

## Pairing Protocol

### QR Code Generation

**Format:**
```
HYDRA://pair?token=<256-bit-hex>&device_id=<id>&port=<port>&ip=<ip>
```

**Example:**
```
HYDRA://pair?token=a1b2c3d4e5f6...&device_id=S25-ABC123&port=4433&ip=192.168.1.100
```

**Generation (Samsung):**
1. Generate 256-bit random token
2. Get local IP address
3. Get device ID
4. Encode as QR code
5. Display on screen

**Scanning (iPhone):**
1. Scan QR code
2. Parse URL
3. Extract token, IP, port, device_id
4. Connect via QUIC
5. Send pairing request with token

### Token Exchange

**PairingRequest:**
```protobuf
message PairingRequest {
  string token = 1;
  string device_id = 2;
  int64 timestamp = 3;
}
```

**PairingResponse:**
```protobuf
message PairingResponse {
  string session_token = 1;
  int64 expires_at = 2;
  bool success = 3;
}
```

**Validation:**
- Token must match server token
- Token must be within 5-minute window
- Device ID must match

---

## Heartbeat Protocol

### Message Format

```protobuf
message Heartbeat {
  float battery_percent = 1;
  float cpu_temp = 2;
  int64 ram_usage_bytes = 3;
  bool thermal_throttling = 4;
  int32 inference_queue_length = 5;
  int64 timestamp = 6;
}
```

### Frequency

- **Send:** Every 500ms
- **Timeout:** 3 seconds (6 missed heartbeats)
- **Action on timeout:** Mark as offline, trigger failover

### Bidirectional

- Both iPhone and Samsung send heartbeats
- Each responds to other's heartbeat
- Detect disconnection quickly

---

## Error Handling

### Network Errors

**Connection Timeout:**
- Retry with exponential backoff
- Max 5 retries
- Switch to WebRTC if QUIC fails

**Stream Reset:**
- Log error
- Retry chunk upload
- Update job status

**Certificate Error:**
- Reject connection
- Log security event
- Require re-pairing

### Retry Strategy

**Exponential Backoff:**
```
Attempt 1: Wait 1s
Attempt 2: Wait 2s
Attempt 3: Wait 4s
Attempt 4: Wait 8s
Attempt 5: Wait 16s
Attempt 6: Wait 30s (capped)
```

**Circuit Breaker:**
- Open after 10 failures
- Half-open after 60s
- Close after 3 successes

---

## Performance Optimization

### Zero-Copy

**Where Possible:**
- Direct memory mapping
- Buffer reuse
- Stream-based processing

**Limitations:**
- JNI overhead (Android)
- iOS memory restrictions

### Chunked Streaming

- **Chunk size:** 64KB default
- **Parallel uploads:** Multiple streams
- **Reassembly:** On receiver

### Compression

**Optional:**
- Gzip compression for large blobs
- Configurable per job
- Trade-off: CPU vs bandwidth

---

## Security Considerations

### mTLS

- Mutual authentication
- Perfect forward secrecy (ECDHE)
- Certificate pinning

### Token Security

- Ephemeral tokens (5-minute validity)
- Session tokens (24-hour validity)
- Secure storage (Keychain/Keystore)

### Data Encryption

- All data encrypted in transit (TLS 1.3)
- Optional encryption at rest (future)

---

## Monitoring

### Metrics

- **Connection latency:** RTT measurement
- **Throughput:** Bytes per second
- **Error rate:** Failed connections/chunks
- **Heartbeat success rate:** % successful heartbeats

### Logging

- Connection events
- Stream creation/destruction
- Error conditions
- Performance metrics

---

**Document Version:** 1.0  
**Last Updated:** 2024

