/// Environment configs for the app.
#[derive(clap::Parser)]
pub struct Config {
    #[clap(short, long)]
    pub database_url: String,
}