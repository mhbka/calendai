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
    pub jwt_secret: Option<String>
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
                        jwt_secret: self.jwt_secret.ok_or("`jwt_secret` missing from CLI args")?
                    }
                );
            }
        }
        Ok(
            Config {
                database_url: env::var("DATABASE_URL").map_err(|_| {"`DATABASE_URL` missing from env vars"})?,
                jwt_secret: env::var("JWT_SECRET").map_err(|_| {"`JWT_SECRET` missing from env vars"})?
            }
        )
    }
}

/// Environment configs for the app.
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String
}