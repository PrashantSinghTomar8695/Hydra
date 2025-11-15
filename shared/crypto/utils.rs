// Cryptographic utilities for Project Hydra

use sha2::{Sha256, Digest};
use std::time::{SystemTime, UNIX_EPOCH};

/// Compute SHA-256 checksum of data
pub fn compute_checksum(data: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().into()
}

/// Verify checksum
pub fn verify_checksum(data: &[u8], expected: &[u8]) -> bool {
    let computed = compute_checksum(data);
    computed.as_slice() == expected
}

/// Generate ephemeral pairing token (256 bits = 32 bytes)
pub fn generate_pairing_token() -> Vec<u8> {
    use rand::RngCore;
    let mut rng = rand::thread_rng();
    let mut token = vec![0u8; 32];
    rng.fill_bytes(&mut token);
    token
}

/// Generate session token
pub fn generate_session_token() -> String {
    use rand::Rng;
    use rand::distributions::Alphanumeric;
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(64)
        .map(char::from)
        .collect()
}

/// Get current timestamp in seconds since epoch
pub fn current_timestamp() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

/// Check if token is expired
pub fn is_token_expired(issued_at: i64, validity_seconds: i64) -> bool {
    let now = current_timestamp();
    (now - issued_at) > validity_seconds
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_checksum() {
        let data = b"test data";
        let checksum = compute_checksum(data);
        assert!(verify_checksum(data, &checksum));
        assert!(!verify_checksum(b"wrong data", &checksum));
    }

    #[test]
    fn test_token_generation() {
        let token1 = generate_pairing_token();
        let token2 = generate_pairing_token();
        assert_eq!(token1.len(), 32);
        assert_ne!(token1, token2);
    }
}

