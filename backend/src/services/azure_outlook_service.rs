use graph_rs_sdk::{Graph, identity::{ConfidentialClientApplication, PublicClientApplicationBuilder}};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::{api::error::{ApiError, ApiResult}, config::Config, llm::{GeneratedEvents, LLM}, models::outlook::OutlookMailMessage, utils::{azure::{is_access_token_valid, refresh_azure_tokens}, encrypt::{decrypt_token, encrypt_token}}};
use crate::Repositories;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct OutlookListEmailsResponse {
    pub value: Vec<OutlookMailMessage>
}

/// Service for functionality related to Outlook/Azure.
#[derive(Clone, Debug)]
pub struct AzureOutlookService {
    llm: LLM,
    repositories: Repositories,
}

impl AzureOutlookService {
    pub fn new(llm: LLM, repositories: Repositories,) -> Self {
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

    pub async fn fetch_user_emails(&self, user_id: Uuid, config: &Config) -> ApiResult<OutlookListEmailsResponse> {
        let encrypted_access_token = self.repositories.azure_tokens
            .get_encrypted_refresh_and_access_token(user_id)
            .await?
            .1;
        let access_token = decrypt_token(&encrypted_access_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to decrypt the access token".into()))?;

        let client = Graph::new(access_token);

        let response = client.me()
            .messages()
            .list_messages()
            .send()
            .await?
            .error_for_status()?;
        let messages = response
            .json::<OutlookListEmailsResponse>()
            .await?;

        Ok(messages)
    }

    pub async fn generate_events_from_user_email(&self, user_id: Uuid, config: &Config, mail_id: &str, timezone_offset_minutes: i32) -> ApiResult<GeneratedEvents> {
        let encrypted_access_token = self.repositories.azure_tokens
            .get_encrypted_refresh_and_access_token(user_id)
            .await?
            .1;
        let access_token = decrypt_token(&encrypted_access_token, &config.azure_encryption_key)
            .map_err(|_| ApiError::Internal("Failed to decrypt the access token".into()))?;
        
        let client = Graph::new(access_token);

        let chosen_email = client.me()
            .message(mail_id)
            .get_messages()
            .send()
            .await?
            .json::<OutlookMailMessage>()
            .await?;

        // TODO: we only parse the body and ignore any attachments and images; is this fine?
        let generated_events = self.llm
            .events_from_text(chosen_email.body, timezone_offset_minutes)
            .await?;
        
        Ok(generated_events)
    }
}