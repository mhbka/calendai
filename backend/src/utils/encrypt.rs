use aes_gcm::{
    Aes256Gcm, Nonce, aead::{Aead, KeyInit, OsRng, rand_core::RngCore}
};
use base64::{Engine as _, engine::general_purpose};
use sha2::{Sha256, Digest};

// Derive a 32-byte key from your string
fn key_from_string(key_string: &str) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(key_string.as_bytes());
    hasher.finalize().into()
}

// Encrypt a given token with the given key to a base64 string.
pub fn encrypt_token(token: &str, key_string: &str) -> Result<String, ()> {
    let key = key_from_string(key_string);
    let cipher = Aes256Gcm::new(&key.into());
    
    // Generate random nonce
    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    // Encrypt
    let ciphertext = cipher
        .encrypt(nonce, token.as_bytes())
        .map_err(|_| ())?;
    
    // Combine nonce + ciphertext
    let mut result = nonce_bytes.to_vec();
    result.extend_from_slice(&ciphertext);
    
    // Encode as base64 for storage
    Ok(general_purpose::STANDARD.encode(&result))
}

// Decrypt from a base64 string.
pub fn decrypt_token(encrypted_b64: &str, key_string: &str) -> Result<String, ()> {
    let key = key_from_string(key_string);
    let cipher = Aes256Gcm::new(&key.into());
    
    // Decode from base64
    let encrypted = general_purpose::STANDARD
        .decode(encrypted_b64)
        .map_err(|_| ())?;
    
    // Extract nonce and ciphertext
    let (nonce_bytes, ciphertext) = encrypted.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);
    
    // Decrypt
    let plaintext_bytes = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|_| ())?;
    let plaintext = String::from_utf8(plaintext_bytes)
        .map_err(|_| ())?;
    
    Ok(plaintext)
}