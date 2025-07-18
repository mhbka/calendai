use clap::Parser;
use dotenv::dotenv;
use sqlx::postgres::PgPoolOptions;

use crate::config::StartupConfig;

mod config;
mod api;
mod models;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    dotenv().ok();
    let config = StartupConfig::parse()
        .to_config()
        .expect("Failed to load config");
    tracing::info!("Config loaded");
    
    let db = PgPoolOptions::new()
        .max_connections(5)
        .connect(&config.database_url)
        .await
        .expect("Failed to instantiate database");
    tracing::info!("Connected to database");

    sqlx::migrate!()
        .run(&db)
        .await
        .expect("Failed to run migration on database");
    tracing::info!("Successfully ran migrations");

    api::run(config, db)
        .await;
}
