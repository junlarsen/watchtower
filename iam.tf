data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "watchtower_assume_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = var.lambda_execution_role_name
}

resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.watchtower_assume_role.name
}

data "aws_iam_policy_document" "watchtower" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.watchtower.arn]
  }

  dynamic "statement" {
    for_each = var.lambda_execution_role_statements
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = lookup(statement.value, "conditions", [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "watchtower" {
  name   = "${aws_lambda_function.watchtower.function_name}-policy"
  policy = data.aws_iam_policy_document.watchtower.json
}

resource "aws_iam_role_policy_attachment" "watchtower" {
  policy_arn = aws_iam_policy.watchtower.arn
  role       = aws_iam_role.watchtower_assume_role.name
}
