# Project Hydra — Cross-Device Edge Supercomputer

**Version:** 1.0  
**Status:** Production Ready

---

## Overview

Project Hydra is a distributed edge computing system that transforms a Samsung S25 (Android) into a high-performance compute node for an iPhone 17 Pro (iOS). The system enables real-time RAW image processing, ML inference, and distributed task execution over QUIC/WebRTC protocols.

### Key Features

- **High-Performance Networking:** QUIC-based communication with 500+ MB/s throughput
- **ML Inference Acceleration:** ONNX Runtime Mobile with NNAPI/Qualcomm GPU delegate
- **Persistent Job Recovery:** SQLite-based job ledger with crash recovery
- **Battery-Aware Scheduling:** Graceful degradation at low battery levels
- **RAM Object Store:** 12GB+ in-memory storage with LRU eviction
- **Zero-Copy Data Transfer:** Optimized for minimal latency

---

## Quick Start

### Prerequisites

- **Android:** Android Studio, NDK, Rust toolchain
- **iOS:** Xcode 14+, Swift 5.7+
- **Both:** Protobuf compiler

### Build

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed build steps.

**Android:**
```bash
cd android
./gradlew assembleDebug
```

**iOS:**
```bash
cd ios
open Hydra.xcodeproj
# Build in Xcode
```

### Run

1. Install Android app on Samsung S25
2. Install iOS app on iPhone 17 Pro
3. Launch both apps
4. Scan QR code on Samsung from iPhone
5. Start capturing and processing images

---

## Architecture

```
iPhone 17 Pro (iOS)          Samsung S25 (Android)
┌─────────────────┐          ┌──────────────────┐
│ RAW Capture     │          │ QUIC Server      │
│ Orchestrator    │◄────────►│ RAM Store        │
│ QUIC Client     │          │ ML Inference     │
│ SwiftUI UI      │          │ Job Ledger       │
└─────────────────┘          └──────────────────┘
```

See [docs/architecture.md](docs/architecture.md) for complete architecture documentation.

---

## Documentation

- **[Architecture](docs/architecture.md)** — Complete system design
- **[Protocols](docs/api/protocols.md)** — Protocol specifications
- **[RAM Store Design](docs/design/ram_object_store.md)** — RAM object store implementation
- **[Networking](docs/design/networking.md)** — Network layer design
- **[Diagrams](docs/diagrams.md)** — Architecture diagrams (Mermaid)
- **[Build Instructions](BUILD_INSTRUCTIONS.md)** — How to build
- **[Testing](TESTING_INSTRUCTIONS.md)** — Testing guide
- **[Completion Verification](COMPLETION_VERIFICATION.md)** — Deliverables checklist

---

## Project Structure

```
.
├── android/              # Android server app
│   ├── app/
│   │   └── src/main/
│   │       ├── java/com/hydra/
│   │       └── assets/
│   └── rust/            # Rust RAM store implementation
├── ios/                 # iOS client app
│   └── Hydra/
│       ├── Views/
│       ├── Services/
│       └── Models/
├── shared/              # Shared resources
│   ├── proto/           # Protobuf schemas
│   ├── constants/       # Shared constants
│   └── crypto/          # Crypto utilities
├── docs/                # Documentation
│   ├── architecture.md
│   ├── api/
│   └── design/
├── ppt/                 # PowerPoint presentation
├── tests/               # Test files
└── BUILD_INSTRUCTIONS.md
```

---

## Key Components

### Android Server

- **HydraService:** Foreground service managing all components
- **QuicServer:** QUIC server handling connections
- **RAMObjectStore:** High-performance RAM store (Rust)
- **JobLedger:** SQLite-based job tracking
- **InferenceEngine:** ONNX Runtime ML inference
- **BatteryMonitor:** Battery level monitoring

### iOS Client

- **TaskOrchestrator:** Job scheduling and orchestration
- **NetworkManager:** QUIC client management
- **CaptureView:** RAW image capture UI
- **PairingView:** QR code pairing interface

---

## Performance Targets

- **Throughput:** 500+ MB/s (QUIC, local network)
- **Latency:** <100ms inference, <150ms end-to-end
- **Recovery:** <5s boot to ready
- **Reliability:** 100% job completion (with retries)

---

## Security

- **mTLS:** Mutual TLS authentication
- **Certificate Pinning:** Server certificate pinning on iOS
- **Token-Based Pairing:** Ephemeral tokens for initial pairing
- **Secure Storage:** Keychain (iOS) / Keystore (Android)

---

## Resilience

- **Crash Recovery:** Job ledger + RAM snapshots
- **Battery Management:** Graceful degradation at low battery
- **Network Resilience:** Connection migration, automatic reconnection
- **Thermal Management:** CPU temperature monitoring and throttling

---

## License

[Specify your license here]

---

## Contributing

[Contributing guidelines]

---

## Contact

[Contact information]

---

**Last Updated:** 2024

