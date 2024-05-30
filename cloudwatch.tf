resource "aws_cloudwatch_log_group" "watchtower" {
  name = var.cloudwatch_log_group_name

  skip_destroy      = true
  retention_in_days = var.cloudwatch_log_retention_window
}
