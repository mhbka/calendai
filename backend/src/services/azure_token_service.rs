use graph_rs_sdk::{Graph, identity::{ConfidentialClientApplication, ConfidentialClientApplicationBuilder, PublicClientApplicationBuilder}};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::{api::error::{ApiError, ApiResult}, config::Config, llm::{GeneratedEvents, LLM}, utils::{azure::{is_access_token_valid, refresh_azure_tokens}, encrypt::{decrypt_token, encrypt_token}}};
use crate::Repositories;

/// Service for functionality related to Azure tokens.
#[derive(Clone, Debug)]
pub struct AzureTokenService {
    llm: LLM,
    repositories: Repositories,
}

impl AzureTokenService {
    pub fn new(llm: LLM, repositories: Repositories) -> Self {
        Self {
            llm,
            repositories
        }
    }

    pub async fn store_user_tokens(&self, user_id: Uuid, refresh_token: String, config: &Config) -> ApiResult<()> {
        let refreshed_tokens = refresh_azure_tokens(
            refresh_token, 
            &config.azure_tenant_id, 
            &config.azure_client_id, 
            &config.azure_client_secret
        )
            .await?;

        tracing::trace!("Access token: {}", refreshed_tokens.access_token);
        tracing::trace!("Refresh token: {}", refreshed_tokens.refresh_token);

        let encrypted_access_token = encrypt_token(&refreshed_tokens.access_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to encrypt the access token".into()))?;
        let encrypted_refresh_token = encrypt_token(&refreshed_tokens.refresh_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to encrypt the refresh token".into()))?;
        self.repositories.azure_tokens
            .insert_encrypted_refresh_and_access_token(user_id, &encrypted_refresh_token, &encrypted_access_token)
            .await?;
        Ok(())
    }

    pub async fn get_valid_access_token(&self, user_id: Uuid, config: &Config) -> ApiResult<String> {
        let (encrypted_refresh_token, encrypted_access_token) = self.repositories.azure_tokens
            .get_encrypted_refresh_and_access_token(user_id)
            .await?;
        let refresh_token = decrypt_token(&encrypted_refresh_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to decrypt the refresh token".into()))?;
        let access_token = decrypt_token(&encrypted_access_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to decrypt the access token".into()))?;

        let token_validity =  {
            match is_access_token_valid(&access_token) {
                Ok(val) => val,
                Err(_) => false
            }
        };
        if !token_validity {
            let refreshed_tokens = refresh_azure_tokens(
                refresh_token, 
                &config.azure_tenant_id, 
                &config.azure_client_id, 
                &config.azure_client_secret
            )
                .await?;
            let encrypted_access_token = encrypt_token(&refreshed_tokens.access_token, &config.azure_encryption_key)
                .map_err(|_| ApiError::Internal("Failed to encrypt the access token".into()))?;
            let encrypted_refresh_token = encrypt_token(&refreshed_tokens.refresh_token, &config.azure_encryption_key)
                .map_err(|_| ApiError::Internal("Failed to encrypt the refresh token".into()))?;
            self.repositories.azure_tokens
                .update_encrypted_refresh_and_access_token(user_id, &encrypted_refresh_token, &encrypted_access_token)
                .await?;
            return Ok(refreshed_tokens.access_token);
            }

        Ok(access_token)
    }
}