# Project Hydra — Architecture Diagrams

All diagrams are in Mermaid format and can be rendered using Mermaid-compatible tools.

---

## System Architecture Diagram

```mermaid
graph TB
    subgraph iPhone["iPhone 17 Pro (iOS)"]
        RAW[RAW Capture Pipeline]
        ORCH[Task Orchestrator]
        QUIC_C[QUIC Client]
        WEBRTC_C[WebRTC Client]
        UI[SwiftUI Interface]
        
        RAW --> ORCH
        ORCH --> QUIC_C
        ORCH --> WEBRTC_C
        QUIC_C --> UI
        WEBRTC_C --> UI
    end
    
    subgraph Samsung["Samsung S25 (Android)"]
        QUIC_S[QUIC Server]
        WEBRTC_S[WebRTC Server]
        RAM[RAM Object Store]
        ML[ML Inference Engine]
        LEDGER[Job Ledger]
        FS[File Storage]
        SERVICE[Foreground Service]
        
        QUIC_S --> RAM
        WEBRTC_S --> RAM
        RAM --> ML
        ML --> LEDGER
        RAM --> FS
        SERVICE --> QUIC_S
        SERVICE --> LEDGER
    end
    
    QUIC_C <-->|QUIC Streams| QUIC_S
    WEBRTC_C <-->|DataChannel| WEBRTC_S
    
    style iPhone fill:#007AFF
    style Samsung fill:#1428A0
```

---

## Component Diagram

```mermaid
graph LR
    subgraph Android["Android Components"]
        A1[QUIC Server<br/>msquic/quiche]
        A2[WebRTC Server<br/>libwebrtc]
        A3[RAM Store<br/>Rust + JNI]
        A4[ML Engine<br/>ONNX Runtime]
        A5[Job Ledger<br/>SQLite + Rust]
        A6[File Store<br/>Scoped Storage]
        A7[Foreground Service<br/>Kotlin]
        
        A1 --> A3
        A2 --> A3
        A3 --> A4
        A4 --> A5
        A3 --> A6
        A7 --> A1
        A7 --> A5
    end
    
    subgraph iOS["iOS Components"]
        I1[QUIC Client<br/>msquic]
        I2[WebRTC Client<br/>libwebrtc]
        I3[RAW Capture<br/>AVFoundation]
        I4[Orchestrator<br/>Swift]
        I5[UI Layer<br/>SwiftUI]
        
        I3 --> I4
        I4 --> I1
        I4 --> I2
        I1 --> I5
        I2 --> I5
    end
    
    A1 <--> I1
    A2 <--> I2
    
    style Android fill:#3DDC84
    style iOS fill:#007AFF
```

---

## Network Flow Diagram

```mermaid
sequenceDiagram
    participant iPhone
    participant QUIC
    participant Samsung
    participant RAM
    participant ML
    participant Ledger
    
    iPhone->>QUIC: Connect (mTLS)
    QUIC->>Samsung: Handshake
    Samsung->>iPhone: Certificate + Session Token
    
    iPhone->>Samsung: JobRequest (job_id: abc123)
    Samsung->>Ledger: Create Job Entry
    Ledger-->>Samsung: Job Created
    
    loop For each chunk
        iPhone->>Samsung: ChunkUpload (chunk_index: N)
        Samsung->>RAM: Store Chunk
        RAM-->>Samsung: Stored
        Samsung->>iPhone: ChunkAck
    end
    
    Samsung->>RAM: Get All Chunks (job_id: abc123)
    RAM-->>Samsung: Chunks [0..N]
    Samsung->>ML: Run Inference
    ML-->>Samsung: Results
    Samsung->>Ledger: Update Job Status
    Samsung->>iPhone: JobResponse (Results)
    
    iPhone->>Samsung: Heartbeat
    Samsung->>iPhone: Heartbeat (Battery, Temp, etc.)
```

---

## ML Inference Pipeline

```mermaid
graph TD
    START[Chunk Upload Complete] --> REASSEMBLE[Reassemble Chunks]
    REASSEMBLE --> VALIDATE[Validate Checksums]
    VALIDATE -->|Invalid| ERROR[Return Error]
    VALIDATE -->|Valid| PREPROCESS[Preprocess Image]
    
    PREPROCESS --> LOAD[Load ONNX Model]
    LOAD -->|Not Cached| CACHE[Cache Model]
    LOAD -->|Cached| INFER[Run Inference]
    CACHE --> INFER
    
    INFER --> NNAPI[NNAPI Delegate]
    NNAPI --> GPU[Qualcomm GPU]
    GPU --> POSTPROCESS[Post-process Results]
    
    POSTPROCESS --> SERIALIZE[Serialize Output]
    SERIALIZE --> STORE[Store in RAM]
    STORE --> RESPONSE[Send JobResponse]
    
    INFER -->|Battery < 12%| PAUSE[Pause Inference]
    PAUSE --> CHECKPOINT[Save Checkpoint]
    CHECKPOINT --> ALERT[Send BatteryAlert]
    
    style GPU fill:#FF6B6B
    style NNAPI fill:#4ECDC4
```

---

## RAM Object Store Internal Layout

```mermaid
graph TB
    subgraph Store["RAM Object Store"]
        CACHE[HashMap<br/>Key: job_id:chunk_index<br/>Value: ChunkData]
        LRU[LRU List<br/>Head → Tail<br/>MRU → LRU]
        TTL[TTL Manager<br/>Background Thread]
        SNAP[Snapshot Manager<br/>WAL + Snapshots]
        
        CACHE --> LRU
        LRU --> EVICT[Eviction Policy]
        TTL --> EVICT
        EVICT --> SNAP
        SNAP --> DISK[Disk Checkpoint]
    end
    
    subgraph Chunk["ChunkData Structure"]
        CD1[job_id: String]
        CD2[chunk_index: u32]
        CD3[data: Vec<u8>]
        CD4[checksum: SHA-256]
        CD5[timestamp: i64]
        CD6[ttl: i64]
        CD7[access_count: u32]
    end
    
    CACHE --> Chunk
    
    style Store fill:#FFD93D
    style Chunk fill:#95E1D3
```

---

## QUIC Stream Multiplexing

```mermaid
graph LR
    subgraph QUIC["QUIC Connection"]
        STREAM0[Stream 0<br/>Control<br/>Heartbeat, Pairing]
        STREAM1[Stream 1<br/>Job abc123<br/>Chunks 0-10]
        STREAM2[Stream 2<br/>Job def456<br/>Chunks 0-5]
        STREAMN[Stream N<br/>Job xyz789<br/>Chunks 0-20]
    end
    
    STREAM0 --> APP0[Application Layer]
    STREAM1 --> APP1[Application Layer]
    STREAM2 --> APP2[Application Layer]
    STREAMN --> APPN[Application Layer]
    
    APP0 --> HANDLER0[Control Handler]
    APP1 --> HANDLER1[Job Handler 1]
    APP2 --> HANDLER2[Job Handler 2]
    APPN --> HANDLERN[Job Handler N]
    
    HANDLER1 --> RAM1[RAM Store]
    HANDLER2 --> RAM2[RAM Store]
    HANDLERN --> RAMN[RAM Store]
    
    style QUIC fill:#6C5CE7
    style RAM1 fill:#FFD93D
    style RAM2 fill:#FFD93D
    style RAMN fill:#FFD93D
```

---

## WebRTC Fallback Flow

```mermaid
sequenceDiagram
    participant iPhone
    participant QUIC
    participant WebRTC
    participant Samsung
    
    iPhone->>QUIC: Attempt Connection
    QUIC->>iPhone: Connection Failed (3 retries)
    
    iPhone->>WebRTC: Initiate Fallback
    WebRTC->>Samsung: SDP Offer
    Samsung->>WebRTC: SDP Answer
    WebRTC->>Samsung: ICE Candidates
    Samsung->>WebRTC: ICE Candidates
    
    WebRTC->>WebRTC: Establish Connection
    
    loop For each chunk
        iPhone->>WebRTC: Send Frame (Custom Protocol)
        WebRTC->>Samsung: DataChannel Message
        Samsung->>WebRTC: Validate & Reassemble
        WebRTC->>Samsung: Chunk Complete
        Samsung->>WebRTC: ChunkAck
        WebRTC->>iPhone: Acknowledgment
    end
    
    Samsung->>WebRTC: JobResponse
    WebRTC->>iPhone: Results
```

---

## Crash Recovery Flow

```mermaid
sequenceDiagram
    participant iPhone
    participant Samsung
    participant Ledger
    participant RAM
    participant Snapshot
    
    Note over Samsung: Normal Operation
    Samsung->>Ledger: Flush Job State (every 500ms)
    Samsung->>Snapshot: Create Snapshot (every 30s)
    
    Note over Samsung: CRASH / REBOOT
    
    Samsung->>Snapshot: Load Latest Snapshot
    Snapshot-->>Samsung: Restore RAM State
    Samsung->>Ledger: Load Job Ledger
    Ledger-->>Samsung: Incomplete Jobs List
    
    Samsung->>RAM: Reconcile with Ledger
    RAM-->>Samsung: Missing Chunks Identified
    
    iPhone->>Samsung: Reconnect
    Samsung->>iPhone: RecoveryState Message
    
    iPhone->>Samsung: JobStatusRequest (job_id: abc123)
    Samsung->>Ledger: Query Job Status
    Ledger-->>Samsung: Completed: 7/10 chunks
    Samsung->>iPhone: JobStatus (chunks 7-9 missing)
    
    loop Resend missing chunks
        iPhone->>Samsung: ChunkUpload (chunk_index: 7)
        Samsung->>RAM: Store Chunk
        Samsung->>iPhone: ChunkAck
    end
    
    Samsung->>RAM: Get All Chunks
    RAM-->>Samsung: Complete Job Data
    Samsung->>iPhone: JobResponse (Results)
```

---

## Battery-Aware Scheduling

```mermaid
stateDiagram-v2
    [*] --> Normal: Battery > 15%
    
    Normal --> AcceptJobs: New Job Request
    AcceptJobs --> Processing: Job Accepted
    Processing --> Complete: Inference Done
    Complete --> Normal: Return Results
    
    Normal --> LowBattery: Battery <= 15%
    LowBattery --> RejectJobs: New Job Request
    RejectJobs --> LowBattery: Job Rejected
    LowBattery --> PauseInference: Battery <= 12%
    
    PauseInference --> Checkpoint: Save State
    Checkpoint --> Alert: Send BatteryAlert
    Alert --> Critical: Battery <= 10%
    
    Critical --> Shutdown: Emergency Shutdown
    Shutdown --> DumpRAM: Save RAM to Disk
    DumpRAM --> [*]: Power Off
    
    Normal --> Recharge: Charging
    Recharge --> Normal: Battery > 15%
```

---

**Document Version:** 1.0  
**Last Updated:** 2024

