data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.target_directory
  output_path = "${var.output_directory}/watchtower-.zip"
}

resource "aws_lambda_function" "watchtower" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.watchtower_assume_role.arn

  filename         = data.archive_file.source.output_path
  source_code_hash = data.archive_file.source.output_base64sha256

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
