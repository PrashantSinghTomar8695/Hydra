# RAM Object Store Design

**Component:** RAM Object Store (Samsung S25)  
**Language:** Rust  
**Interface:** JNI to Kotlin

---

## Overview

The RAM Object Store is a high-performance, in-memory storage system designed to hold up to 12GB+ of data with LRU eviction, TTL expiration, chunked storage, and crash recovery capabilities.

---

## Architecture

### Core Components

1. **LRU Cache:** HashMap + doubly-linked list
2. **TTL Manager:** Background thread for expiration
3. **Chunk Manager:** Reassembly and validation
4. **Snapshot Manager:** Periodic snapshots and journaling
5. **Lock Manager:** Thread-safe access control

### Data Structures

```rust
use std::collections::HashMap;
use std::sync::{RwLock, Arc};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct ChunkData {
    pub job_id: String,
    pub chunk_index: u32,
    pub data: Vec<u8>,
    pub checksum: [u8; 32], // SHA-256
    pub timestamp: i64,
    pub ttl: i64, // TTL in seconds
    pub access_count: u32,
    pub last_access: i64,
}

pub struct LRUNode {
    pub key: String,
    pub chunk: Arc<ChunkData>,
    pub prev: Option<*mut LRUNode>,
    pub next: Option<*mut LRUNode>,
}

pub struct RAMObjectStore {
    // Primary storage
    cache: Arc<RwLock<HashMap<String, Arc<ChunkData>>>>,
    
    // LRU tracking
    lru_head: Arc<RwLock<Option<*mut LRUNode>>>,
    lru_tail: Arc<RwLock<Option<*mut LRUNode>>>,
    lru_map: Arc<RwLock<HashMap<String, *mut LRUNode>>>,
    
    // Configuration
    max_size_bytes: usize,
    current_size_bytes: Arc<RwLock<usize>>,
    
    // TTL management
    ttl_check_interval: u64, // seconds
    
    // Snapshot
    snapshot_path: String,
    journal_path: String,
}
```

---

## LRU Implementation

### Algorithm

1. **Lookup:** O(1) via HashMap
2. **Insert:** O(1) - add to head
3. **Evict:** O(1) - remove from tail
4. **Update:** O(1) - move to head on access

### Doubly-Linked List

```
Head → [Node1] ↔ [Node2] ↔ [Node3] ↔ [Node4] ← Tail
        (MRU)                              (LRU)
```

**Operations:**
- **Access:** Move node to head
- **Insert:** Add new node at head
- **Evict:** Remove node from tail

### Thread Safety

- **RwLock:** Multiple readers, single writer
- **Atomic operations:** For size tracking
- **Lock ordering:** Always acquire cache lock before LRU lock

---

## TTL Management

### Expiration Strategy

1. **Background thread:** Runs every 5 seconds
2. **Check all chunks:** Compare `timestamp + ttl` with current time
3. **Evict expired:** Remove from cache and LRU
4. **Update size:** Decrement `current_size_bytes`

### TTL Configuration

- **Default TTL:** 300 seconds (5 minutes)
- **Job-specific TTL:** Set per job
- **Infinite TTL:** Use -1 (never expire)

---

## Chunking Strategy

### Variable Chunk Size

- **Default:** 64KB
- **Large blobs:** Up to 1MB per chunk
- **Small blobs:** As small as 1KB

### Chunk Key Format

```
"{job_id}:{chunk_index}"
```

Example: `"abc123:0"`, `"abc123:1"`, etc.

### Reassembly

**Process:**
1. Store chunks independently
2. Track completion via `JobLedger`
3. On request, fetch all chunks for job_id
4. Sort by chunk_index
5. Concatenate data
6. Validate checksums

**Validation:**
- Each chunk has SHA-256 checksum
- Validate on store and retrieve
- Reject invalid chunks

---

## Snapshot & Recovery

### Write-Ahead Log (WAL)

**Format:**
```
[Operation Type: 1 byte]
[Timestamp: 8 bytes]
[Key Length: 4 bytes]
[Key: Variable]
[Data Length: 4 bytes]
[Data: Variable]
```

**Operations:**
- `PUT`: Store chunk
- `DELETE`: Remove chunk
- `CHECKPOINT`: Snapshot marker

### Snapshot Format

**Binary Format:**
```
[Magic: 4 bytes "HYDR"]
[Version: 4 bytes]
[Chunk Count: 4 bytes]
[Chunk 1: Key + Data]
[Chunk 2: Key + Data]
...
[Checksum: 32 bytes SHA-256]
```

### Snapshot Frequency

- **Periodic:** Every 30 seconds
- **On eviction:** If chunk is important (high access_count)
- **On shutdown:** Full snapshot
- **On battery critical:** Emergency snapshot

### Recovery Process

1. **On boot:** Load latest snapshot
2. **Replay WAL:** Apply journal entries after snapshot
3. **Reconcile with Ledger:** Match job states
4. **Restore in-progress:** Mark chunks as available
5. **Ready:** Accept new jobs

---

## Locking Model

### Read Operations

```rust
let cache = self.cache.read().unwrap();
let chunk = cache.get(&key);
// Read lock held during access
```

### Write Operations

```rust
let mut cache = self.cache.write().unwrap();
cache.insert(key, chunk);
// Write lock held during modification
```

### Deadlock Prevention

- **Lock ordering:** Always acquire in same order
  1. Cache lock
  2. LRU lock
  3. Size lock
- **Timeout:** Use `try_lock` with timeout
- **Avoid nested locks:** Release before acquiring new

---

## Eviction Policy

### When to Evict

1. **Size limit reached:** `current_size_bytes >= max_size_bytes`
2. **TTL expired:** Chunk past expiration
3. **Manual eviction:** Requested by application

### Eviction Algorithm

```
1. Check TTL expiration first (free eviction)
2. If still full, evict LRU chunk
3. If chunk is "important" (high access_count):
   - Write to disk checkpoint
   - Update ledger
4. Remove from cache and LRU
5. Update size
```

### Important Chunk Detection

- **Threshold:** `access_count > 10`
- **Action:** Save to disk before eviction
- **Recovery:** Load from disk if needed

---

## Performance Optimizations

### Zero-Copy (Where Possible)

- **Memory mapping:** For large blobs (future)
- **Buffer reuse:** Pool of buffers
- **Direct memory:** Avoid unnecessary copies

### Batch Operations

- **Batch insert:** Multiple chunks in one lock
- **Batch evict:** Evict multiple at once
- **Batch snapshot:** Snapshot multiple chunks

### Memory Efficiency

- **Compression:** Optional compression for old chunks
- **Deduplication:** Detect duplicate chunks (future)
- **Pagination:** Large chunks split across pages

---

## API Interface

### Rust API

```rust
impl RAMObjectStore {
    pub fn new(max_size_bytes: usize, snapshot_path: String) -> Self;
    
    pub fn put(&self, job_id: &str, chunk_index: u32, data: Vec<u8>, ttl: i64) -> Result<()>;
    
    pub fn get(&self, job_id: &str, chunk_index: u32) -> Option<Arc<ChunkData>>;
    
    pub fn get_all_chunks(&self, job_id: &str) -> Vec<Arc<ChunkData>>;
    
    pub fn delete(&self, job_id: &str, chunk_index: u32) -> Result<()>;
    
    pub fn delete_job(&self, job_id: &str) -> Result<()>;
    
    pub fn snapshot(&self) -> Result<()>;
    
    pub fn restore(&self) -> Result<()>;
    
    pub fn get_stats(&self) -> StoreStats;
}
```

### JNI Interface

```rust
#[no_mangle]
pub extern "C" fn Java_com_hydra_RAMStore_nativePut(
    env: JNIEnv,
    obj: JObject,
    job_id: JString,
    chunk_index: jint,
    data: jbyteArray,
    ttl: jlong,
) -> jboolean;

#[no_mangle]
pub extern "C" fn Java_com_hydra_RAMStore_nativeGet(
    env: JNIEnv,
    obj: JObject,
    job_id: JString,
    chunk_index: jint,
) -> jbyteArray;
```

---

## Testing

### Unit Tests

- LRU eviction correctness
- TTL expiration
- Chunk reassembly
- Snapshot/restore
- Thread safety

### Integration Tests

- Concurrent access
- Large dataset (12GB)
- Crash recovery
- Performance benchmarks

---

## Metrics

### Tracked Metrics

- **Size:** Current usage, peak usage
- **Hit rate:** Cache hit percentage
- **Eviction rate:** Chunks evicted per second
- **Latency:** Average get/put time
- **Snapshot time:** Time to create snapshot

---

**Document Version:** 1.0  
**Last Updated:** 2024

