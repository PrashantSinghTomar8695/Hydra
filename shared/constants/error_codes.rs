// Error codes matching protobuf definitions
pub const ERROR_UNKNOWN: i32 = 0;
pub const ERROR_NETWORK_TIMEOUT: i32 = 1;
pub const ERROR_INVALID_JOB_ID: i32 = 2;
pub const ERROR_INVALID_CHUNK: i32 = 3;
pub const ERROR_BATTERY_LOW: i32 = 4;
pub const ERROR_THERMAL_THROTTLE: i32 = 5;
pub const ERROR_INFERENCE_FAILED: i32 = 6;
pub const ERROR_STORAGE_FULL: i32 = 7;
pub const ERROR_AUTHENTICATION_FAILED: i32 = 8;
pub const ERROR_STREAM_RESET: i32 = 9;
pub const ERROR_DEVICE_OFFLINE: i32 = 10;
pub const ERROR_JOB_NOT_FOUND: i32 = 11;
pub const ERROR_CHUNK_CHECKSUM_FAILED: i32 = 12;

pub fn error_code_to_string(code: i32) -> &'static str {
    match code {
        ERROR_UNKNOWN => "Unknown error",
        ERROR_NETWORK_TIMEOUT => "Network timeout",
        ERROR_INVALID_JOB_ID => "Invalid job ID",
        ERROR_INVALID_CHUNK => "Invalid chunk",
        ERROR_BATTERY_LOW => "Battery low",
        ERROR_THERMAL_THROTTLE => "Thermal throttling",
        ERROR_INFERENCE_FAILED => "Inference failed",
        ERROR_STORAGE_FULL => "Storage full",
        ERROR_AUTHENTICATION_FAILED => "Authentication failed",
        ERROR_STREAM_RESET => "Stream reset",
        ERROR_DEVICE_OFFLINE => "Device offline",
        ERROR_JOB_NOT_FOUND => "Job not found",
        ERROR_CHUNK_CHECKSUM_FAILED => "Chunk checksum failed",
        _ => "Unknown error code",
    }
}

