use clap::Parser;
use dotenv::dotenv;
use sqlx::postgres::PgPoolOptions;

use crate::config::StartupConfig;

mod config;
mod api;
mod models;

#[tokio::main]
async fn main() {
    dotenv().ok();
    let config = StartupConfig::parse()
        .to_config()
        .expect("Failed to load config");
    let db = PgPoolOptions::new()
        .max_connections(50)
        .connect(&config.database_url)
        .await
        .expect("Failed to instantiate database");
    sqlx::migrate!()
        .run(&db)
        .await
        .expect("Failed to run migration on database");
    api::run(config, db)
        .await;
}
