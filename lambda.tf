data "archive_file" "watchtower" {
  type = "zip"
  source {
    // Sensitive to prevent the binary code from being printed to the console during Terraform apply or plan
    content  = sensitive(data.http.asset.response_body)
    filename = "bootstrap"
  }
  output_path = "${var.output_directory}/watchtower-lambda.zip"
}

resource "aws_lambda_function" "watchtower" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.watchtower_assume_role.arn

  filename         = data.archive_file.watchtower.output_path
  source_code_hash = data.archive_file.watchtower.output_base64sha256

  handler     = var.handler
  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = merge({
      RUST_BACKTRACE        = "1",
      RUST_LOG              = "trace",
      AWS_LAMBDA_LOG_FORMAT = "json",
      AWS_LAMBDA_LOG_LEVEL  = "trace"
    }, var.environment_variables)
  }
}

resource "aws_lambda_permission" "watchtower_eventbridge" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.watchtower.function_name
  principal     = "events.amazonaws.com"
}
