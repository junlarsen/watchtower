data "github_release" "watchtower" {
  repository  = "watchtower"
  owner       = "junlarsen"
  retrieve_by = var.watchtower_release == "latest" ? "latest" : "tag"
  release_tag = var.watchtower_release != "latest" ? var.watchtower_release : null
}

locals {
  assets = {
    for asset in data.github_release.watchtower.assets : asset.name => asset.browser_download_url
    if asset.name == "watchtower-lambda-x86_64-unknown-linux-gnu"
  }
}

data "http" "asset" {
  url                = local.assets["watchtower-lambda-x86_64-unknown-linux-gnu"]
  request_timeout_ms = 10000

  request_headers = {
    "Accept" = "application/octet-stream"
  }
}
