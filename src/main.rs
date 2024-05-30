use std::ops::Sub;

use anyhow::{bail, Context};
use aws_sdk_costexplorer::types::{DateInterval, Granularity};
use chrono::{Duration, NaiveDate, Utc};
use lambda_http::service_fn;
use lambda_runtime::tracing::init_default_subscriber;
use lambda_runtime::LambdaEvent;
use serde_json::{json, Value};
use serenity::all::{CreateEmbedFooter, ExecuteWebhook};
use serenity::builder::CreateEmbed;
use serenity::http::Http;
use serenity::model::webhook::Webhook;
use serenity::model::Color;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    init_default_subscriber();
    let handler = service_fn(handler);
    lambda_runtime::run(handler)
        .await
        .expect("failed to run lambda");
    Ok(())
}

#[tracing::instrument(err)]
async fn handler(_: LambdaEvent<Value>) -> Result<Value, lambda_runtime::Error> {
    tracing::debug!("begin processing handler");
    let aws_config = aws_config::load_from_env().await;
    let cost_explorer = aws_sdk_costexplorer::Client::new(&aws_config);
    let metrics = get_cost_metrics(&cost_explorer).await?;
    dispatch_discord_webhook(&metrics).await?;
    tracing::debug!("handler completed successfully");

    Ok(json!({ "message": "OK" }))
}

/// Type representing the cost metrics that we're interested in.
#[derive(Debug)]
struct CostMetrics {
    pub total_cost: f64,
    pub daily_cost: Vec<(NaiveDate, f64)>,
}

async fn get_cost_metrics(client: &aws_sdk_costexplorer::Client) -> anyhow::Result<CostMetrics> {
    tracing::debug!("beginning cost metrics query");
    let query_interval = {
        let now = Utc::now();
        DateInterval::builder()
            .start(format!(
                "{}",
                now.sub(Duration::days(15)).format("%Y-%m-%d")
            ))
            .end(format!("{}", now.format("%Y-%m-%d")))
            .build()?
    };
    tracing::debug!(
        "querying daily granulated unblended cost metrics for time interval {:?}",
        query_interval
    );
    let metrics = client
        .get_cost_and_usage()
        .granularity(Granularity::Daily)
        .metrics("UnblendedCost")
        .time_period(query_interval)
        .send()
        .await?;
    // Commit some crimes to unnest the disturbingly nested response from AWS
    if let Some(metrics) = metrics.results_by_time {
        let day_segments = metrics.iter().filter_map(|result| {
            let Some(ref date) = result.time_period else {
                tracing::warn!("no date found for cost metric");
                return None;
            };
            let date = date.start.parse::<NaiveDate>().ok()?;
            let Some(ref total) = result.total else {
                tracing::warn!("no total cost found for date {}", date);
                return None;
            };
            let cost = total
                .get("UnblendedCost")
                .and_then(|cost| cost.amount.as_deref())
                .and_then(|amount| amount.parse::<f64>().ok())?;
            Some((date, cost))
        });
        let segments = day_segments.collect::<Vec<_>>();
        let sum = segments.iter().map(|(_, cost)| cost).sum();
        tracing::debug!("found {} daily cost segments for interval", segments.len());
        return Ok(CostMetrics {
            total_cost: sum,
            daily_cost: segments,
        });
    }
    bail!("no cost metrics found");
}

async fn dispatch_discord_webhook(metrics: &CostMetrics) -> anyhow::Result<()> {
    tracing::debug!("dispatching discord webhook");
    let webhook_url = std::env::var("DISCORD_WEBHOOK_URL")?;

    let http = Http::new("");
    let webhook = Webhook::from_url(&http, &webhook_url)
        .await
        .context("failed to fetch webhook")?;
    let mut embed = CreateEmbed::new()
        .title("Cost metrics from WatchTower")
        .description("Here are the cost metrics for the last 15 days")
        .color(Color::from(0x48b9c7))
        .footer(CreateEmbedFooter::new(format!(
            "Total sum for the last 15 days: ${}",
            metrics.total_cost
        )));
    for (date, cost) in &metrics.daily_cost {
        embed = embed.field(format!("{}", date), format!("${}", cost), true);
    }
    tracing::debug!("sending webhook with embed {:?}", embed);

    let builder = ExecuteWebhook::new().username("Watchtower").embed(embed);
    webhook.execute(&http, false, builder).await?;
    Ok(())
}
