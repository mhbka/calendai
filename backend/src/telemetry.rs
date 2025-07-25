use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter, Registry};
use tracing_subscriber::fmt::layer;

pub fn init_tracing() {
    let env_filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("trace,sqlx=warn,tower_http=trace"));

    let fmt_layer = layer()
        .with_target(true)
        .with_thread_ids(true)
        .with_line_number(true);

    Registry::default()
        .with(env_filter)
        .with(fmt_layer)
        .init();
}