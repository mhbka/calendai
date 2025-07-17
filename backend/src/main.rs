use clap::Parser;
use dotenv::dotenv;
use config::Config;
use sqlx::postgres::PgPoolOptions;

mod config;
mod api;

#[tokio::main]
async fn main() {
    dotenv().ok();
    let config = Config::parse();
    let db: sqlx::Pool<sqlx::Postgres> = PgPoolOptions::new()
        .max_connections(50)
        .connect(&config.database_url)
        .await
        .expect("Should successfully instantiate the database");
    sqlx::migrate!()
        .run(&db)
        .await
        .expect("Migration should succeeed");
}
