variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "lambda_execution_role_name" {
  description = "The name of the IAM role that the Lambda function will assume"
  type        = string
}

variable "lambda_execution_role_statements" {
  description = "A list of statements that define the permissions for the Lambda function"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
    conditions = list(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  default = []
}

variable "handler" {
  description = "The entry point for the Lambda function"
  type        = string
  default     = "bootstrap"
}

variable "runtime" {
  description = "The runtime for the Lambda function"
  type        = string
  default     = "provided.al2023"
}

variable "timeout" {
  description = "The amount of time that Lambda allows a function to run before stopping it"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "The amount of memory that Lambda allocates to the function"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "A map of environment variables to set for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Logs log group to which the Lambda function will send logs"
  type        = string
}

variable "cloudwatch_log_retention_window" {
  description = "The number of days to retain log events in the CloudWatch Logs log group"
  type        = number
  default     = 14
}

variable "target_directory" {
  description = "The directory containing the source code for the Lambda function"
  type        = string
  default     = "target/lambda/watchtower/"
}

variable "output_directory" {
  description = "The directory in which to store the Lambda function deployment package"
  type        = string
  default     = "dist/lambda/watchtower"
}

variable "rule_expression" {
  description = "The rule expression that defines the schedule for the Lambda function"
  type        = string
  default     = "cron(0 6 * * ? *)"
}
