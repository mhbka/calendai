use std::env;

/// Startup config for the app.
/// 
/// `by_cli` denotes whether to use CLI-supplied values.
/// If this is false or `None`, environment variables/.env file will be used instead.
#[derive(clap::Parser)]
pub struct StartupConfig {
    #[clap(short, long)]
    by_cli: Option<bool>,
    #[clap(short, long)]
    pub database_url: Option<String>,
    #[clap(short, long)]
    pub jwt_secret: Option<String>,
    #[clap(short, long)]
    pub gemini_key: Option<String>,
    #[clap(short, long)]
    pub gemini_model: Option<String>,
    #[clap(short, long)]
    pub azure_tenant_id: Option<String>,
    #[clap(short, long)]
    pub azure_client_id: Option<String>,
    #[clap(short, long)]
    pub azure_client_secret: Option<String>,
    #[clap(short, long)]
    pub azure_encryption_key: Option<String>
}

impl StartupConfig {
    /// Converts to a `Config` by either pulling from CLI values or env vars.
    /// 
    /// Returns an `Err` if any value wasn't present.
    pub fn to_config(self) -> Result<Config, String> {
        if let Some(by_cli) = self.by_cli {
            if by_cli {
                return Ok(
                    Config {
                        database_url: self.database_url.ok_or("`database_url` missing from CLI args")?,
                        jwt_secret: self.jwt_secret.ok_or("`jwt_secret` missing from CLI args")?,
                        gemini_key: self.gemini_key.ok_or("`gemini_key` missing from CLI args")?,
                        gemini_model: self.gemini_model.ok_or("`gemini_key` missing from CLI args")?,
                        azure_tenant_id: self.azure_tenant_id.ok_or("`azure_tenant_id` missing from CLI args")?,
                        azure_client_id: self.azure_client_id.ok_or("`azure_client_id` missing from CLI args")?,
                        azure_client_secret: self.azure_client_secret.ok_or("`azure_client_secret` missing from CLI args")?,
                        azure_encryption_key: self.azure_encryption_key.ok_or("`azure_encryption_key` missing from CLI args")?,
                    }
                );
            }
        }
        Ok(
            Config {
                database_url: env::var("DATABASE_URL").map_err(|_| {"`DATABASE_URL` missing from env vars"})?,
                jwt_secret: env::var("JWT_SECRET").map_err(|_| {"`JWT_SECRET` missing from env vars"})?,
                gemini_key: env::var("GEMINI_KEY").map_err(|_| "`GEMINI_KEY` missing from env vars")?,
                gemini_model: env::var("GEMINI_MODEL").map_err(|_| "`GEMINI_MODEL` missing from env vars")?,
                azure_tenant_id: env::var("AZURE_TENANT_ID").map_err(|_| "`AZURE_TENANT_ID` missing from env vars")?,
                azure_client_id: env::var("AZURE_CLIENT_ID").map_err(|_| "`AZURE_CLIENT_ID` missing from env vars")?,
                azure_client_secret: env::var("AZURE_CLIENT_SECRET").map_err(|_| "`AZURE_CLIENT_SECRET` missing from env vars")?,
                azure_encryption_key: env::var("AZURE_ENCRYPTION_KEY").map_err(|_| "`AZURE_ENCRYPTION_KEY` missing from env vars")?,
            }
        )
    }
}

/// Environment configs for the app.
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub gemini_key: String,
    pub gemini_model: String,
    pub azure_tenant_id: String,
    pub azure_client_id: String,
    pub azure_client_secret: String,
    pub azure_encryption_key: String
}