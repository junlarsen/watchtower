use crate::CostMetrics;
use anyhow::Context;
use serenity::all::{Color, CreateEmbed, CreateEmbedFooter, ExecuteWebhook, Http, Webhook};

pub async fn dispatch_discord_webhook(metrics: &CostMetrics) -> anyhow::Result<()> {
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
