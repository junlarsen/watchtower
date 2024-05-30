use lambda_http::service_fn;
use lambda_runtime::LambdaEvent;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::{fmt, EnvFilter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(fmt::layer().with_ansi(std::env::var("TERM").is_ok()))
        .with(EnvFilter::from_default_env())
        .init();
    let handler = service_fn(handler);
    lambda_runtime::run(handler)
        .await
        .expect("failed to run lambda");
    Ok(())
}

#[tracing::instrument(skip(event), err)]
async fn handler(event: LambdaEvent<()>) -> Result<(), lambda_runtime::Error> {
    tracing::debug!("begin processing handler");
    Ok(())
}
