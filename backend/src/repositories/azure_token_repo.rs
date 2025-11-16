use sqlx::PgPool;
use uuid::Uuid;

use crate::{repositories::RepoResult, utils::encrypt::encrypt_token};

/// Abstraction for interacting with the `azure_token` table.
#[derive(Clone, Debug)]
pub struct AzureTokensRepository {
    db: PgPool,
}

impl AzureTokensRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    pub async fn insert_encrypted_refresh_and_access_token(&self, user_id: Uuid, encrypted_refresh_token: &str, encrypted_access_token: &str) -> RepoResult<()> {
        sqlx::query!(
            r#"
                insert into azure_tokens
                (user_id, encrypted_refresh_token, encrypted_access_token)
                values
                ($1, $2, $3)
                on conflict (user_id) do update
                set 
                    encrypted_refresh_token = $2,
                    encrypted_access_token = $3
            "#,
            user_id,
            encrypted_refresh_token,
            encrypted_access_token
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }

    pub async fn update_encrypted_refresh_and_access_token(&self, user_id: Uuid, encrypted_refresh_token: &str, encrypted_access_token: &str) -> RepoResult<()> {
        sqlx::query!(
            r#"
                update azure_tokens
                set encrypted_refresh_token = $1, encrypted_access_token = $2
                where user_id = $3
            "#,
            encrypted_refresh_token,
            encrypted_access_token,
            user_id
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }

    pub async fn update_encrypted_access_token(&self, user_id: Uuid, encrypted_access_token: &str) -> RepoResult<()> {
        sqlx::query!(
            r#"
                update azure_tokens
                set encrypted_access_token = $1
                where user_id = $2
            "#,
            encrypted_access_token,
            user_id
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }

    pub async fn get_encrypted_refresh_and_access_token(&self, user_id: Uuid) -> RepoResult<(String, String)> {
        let tokens = sqlx::query!(
            r#"
                select encrypted_refresh_token, encrypted_access_token
                from azure_tokens
                where user_id = $1
            "#,
            user_id
        )
            .fetch_one(&self.db)
            .await?;
        Ok((tokens.encrypted_refresh_token, tokens.encrypted_access_token))
    }
}