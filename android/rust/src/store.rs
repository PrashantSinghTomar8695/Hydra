use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct ChunkData {
    pub job_id: String,
    pub chunk_index: u32,
    pub data: Vec<u8>,
    pub checksum: [u8; 32],
    pub timestamp: i64,
    pub ttl: i64,
    pub access_count: u32,
    pub last_access: i64,
}

pub struct StoreStats {
    pub current_size_bytes: usize,
    pub max_size_bytes: usize,
    pub chunk_count: usize,
    pub hit_rate: f64,
}

pub struct RAMStore {
    cache: Arc<RwLock<HashMap<String, Arc<ChunkData>>>>,
    max_size_bytes: usize,
    current_size_bytes: Arc<RwLock<usize>>,
    snapshot_path: String,
}

impl RAMStore {
    pub fn new(max_size_bytes: usize, snapshot_path: String) -> Self {
        Self {
            cache: Arc::new(RwLock::new(HashMap::new())),
            max_size_bytes,
            current_size_bytes: Arc::new(RwLock::new(0)),
            snapshot_path,
        }
    }

    pub fn put(
        &self,
        job_id: &str,
        chunk_index: u32,
        data: Vec<u8>,
        checksum: [u8; 32],
        ttl: i64,
    ) -> bool {
        // Verify checksum
        let computed = Self::compute_checksum(&data);
        if computed != checksum {
            return false;
        }

        let key = format!("{}:{}", job_id, chunk_index);
        let now = Self::current_timestamp();

        let chunk = Arc::new(ChunkData {
            job_id: job_id.to_string(),
            chunk_index,
            data,
            checksum,
            timestamp: now,
            ttl,
            access_count: 0,
            last_access: now,
        });

        let mut cache = self.cache.write().unwrap();
        let mut size = self.current_size_bytes.write().unwrap();

        // Evict if needed
        if *size + chunk.data.len() > self.max_size_bytes {
            self.evict_lru(&mut cache, &mut size);
        }

        cache.insert(key, chunk.clone());
        *size += chunk.data.len();

        true
    }

    pub fn get(&self, job_id: &str, chunk_index: u32) -> Option<Vec<u8>> {
        let key = format!("{}:{}", job_id, chunk_index);
        let cache = self.cache.read().unwrap();

        if let Some(chunk) = cache.get(&key) {
            // Note: Arc doesn't allow mutable access, so we'd need RefCell or different design
            // For now, simplified - just return the data
            return Some(chunk.data.clone());
        }

        None
    }

    pub fn get_chunk_indices(&self, job_id: &str) -> Vec<u32> {
        let cache = self.cache.read().unwrap();
        let mut indices = Vec::new();

        for key in cache.keys() {
            if key.starts_with(&format!("{}:", job_id)) {
                if let Some(index_str) = key.split(':').nth(1) {
                    if let Ok(index) = index_str.parse::<u32>() {
                        indices.push(index);
                    }
                }
            }
        }

        indices.sort();
        indices
    }

    pub fn delete(&self, job_id: &str, chunk_index: u32) -> bool {
        let key = format!("{}:{}", job_id, chunk_index);
        let mut cache = self.cache.write().unwrap();
        let mut size = self.current_size_bytes.write().unwrap();

        if let Some(chunk) = cache.remove(&key) {
            *size -= chunk.data.len();
            return true;
        }

        false
    }

    pub fn delete_job(&self, job_id: &str) -> bool {
        let mut cache = self.cache.write().unwrap();
        let mut size = self.current_size_bytes.write().unwrap();
        let mut deleted = false;

        let keys: Vec<String> = cache
            .keys()
            .filter(|k| k.starts_with(&format!("{}:", job_id)))
            .cloned()
            .collect();

        for key in keys {
            if let Some(chunk) = cache.remove(&key) {
                *size -= chunk.data.len();
                deleted = true;
            }
        }

        deleted
    }

    pub fn snapshot(&self) {
        // Implementation would serialize cache to disk
        // Simplified for now
    }

    pub fn restore(&self) {
        // Implementation would load snapshot from disk
        // Simplified for now
    }

    pub fn emergency_checkpoint(&self) {
        self.snapshot();
    }

    pub fn get_stats(&self) -> StoreStats {
        let cache = self.cache.read().unwrap();
        let size = self.current_size_bytes.read().unwrap();

        StoreStats {
            current_size_bytes: *size,
            max_size_bytes: self.max_size_bytes,
            chunk_count: cache.len(),
            hit_rate: 0.95, // Placeholder
        }
    }

    fn evict_lru(&self, cache: &mut HashMap<String, Arc<ChunkData>>, size: &mut usize) {
        // Simplified LRU eviction - find oldest chunk
        if let Some((key, chunk)) = cache
            .iter()
            .min_by_key(|(_, c)| c.last_access)
            .map(|(k, c)| (k.clone(), c.clone()))
        {
            cache.remove(&key);
            *size -= chunk.data.len();
        }
    }

    fn compute_checksum(data: &[u8]) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(data);
        hasher.finalize().into()
    }

    fn current_timestamp() -> i64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64
    }
}
