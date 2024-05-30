resource "aws_cloudwatch_event_rule" "watchtower" {
  name = "${var.lambda_function_name}-rule"

  schedule_expression = var.rule_expression
}

resource "aws_cloudwatch_event_target" "watchtower" {
  arn  = aws_lambda_function.watchtower.arn
  rule = aws_cloudwatch_event_rule.watchtower.name
}
