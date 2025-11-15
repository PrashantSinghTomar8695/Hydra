// Project Hydra Constants

// Network
pub const DEFAULT_QUIC_PORT: u16 = 4433;
pub const DEFAULT_WEBRTC_PORT: u16 = 8080;
pub const MAX_CONCURRENT_STREAMS: usize = 100;
pub const HEARTBEAT_INTERVAL_MS: u64 = 500;
pub const HEARTBEAT_TIMEOUT_MS: u64 = 3000;

// Chunking
pub const DEFAULT_CHUNK_SIZE: usize = 64 * 1024; // 64KB
pub const MAX_CHUNK_SIZE: usize = 1024 * 1024; // 1MB
pub const MIN_CHUNK_SIZE: usize = 1024; // 1KB

// RAM Store
pub const DEFAULT_RAM_STORE_SIZE: usize = 12 * 1024 * 1024 * 1024; // 12GB
pub const DEFAULT_TTL_SECONDS: i64 = 300; // 5 minutes
pub const SNAPSHOT_INTERVAL_SECONDS: u64 = 30;
pub const LEDGER_FLUSH_INTERVAL_MS: u64 = 500;

// Battery
pub const BATTERY_LOW_THRESHOLD: f32 = 15.0; // Stop accepting jobs
pub const BATTERY_CRITICAL_THRESHOLD: f32 = 12.0; // Pause inference
pub const BATTERY_EMERGENCY_THRESHOLD: f32 = 10.0; // Emergency shutdown

// Thermal
pub const CPU_TEMP_WARNING: f32 = 70.0; // Celsius
pub const CPU_TEMP_CRITICAL: f32 = 85.0; // Celsius

// Retry
pub const MAX_RETRIES: u32 = 5;
pub const INITIAL_RETRY_DELAY_MS: u64 = 1000;
pub const MAX_RETRY_DELAY_MS: u64 = 30000;
pub const RETRY_BACKOFF_MULTIPLIER: f64 = 2.0;

// Circuit Breaker
pub const CIRCUIT_BREAKER_FAILURE_THRESHOLD: u32 = 10;
pub const CIRCUIT_BREAKER_HALF_OPEN_DELAY_MS: u64 = 60000;
pub const CIRCUIT_BREAKER_SUCCESS_THRESHOLD: u32 = 3;

// Pairing
pub const PAIRING_TOKEN_VALIDITY_SECONDS: i64 = 300; // 5 minutes
pub const SESSION_TOKEN_VALIDITY_SECONDS: i64 = 86400; // 24 hours

// ML Inference
pub const DEFAULT_INFERENCE_TIMEOUT_MS: u64 = 5000;
pub const MAX_BATCH_SIZE: usize = 32;

// File paths (Android)
pub const LEDGER_DB_PATH: &str = "/data/data/com.hydra/databases/ledger.db";
pub const RAM_SNAPSHOT_DIR: &str = "/data/data/com.hydra/ram_store_snapshots/";
pub const CHECKPOINT_DIR: &str = "/data/data/com.hydra/checkpoints/";

