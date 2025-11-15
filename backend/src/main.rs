use clap::Parser;
use dotenv::dotenv;
use sqlx::postgres::PgPoolOptions;
use crate::{config::StartupConfig, llm::LLM, repositories::Repositories, services::Services};

mod telemetry;
mod config;
mod api;
mod models;
mod llm;
mod services;
mod repositories;
mod auth;
mod utils;

#[tokio::main]
async fn main() {
    dotenv().ok();
    telemetry::init_tracing();
    
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

    let repos = Repositories::new(db.clone());
    let llm = LLM::new(&config);
    let services = Services::new(repos, llm);
    api::run(config, services)
        .await;
}
