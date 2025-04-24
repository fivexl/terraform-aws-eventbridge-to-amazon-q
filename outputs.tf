output "sns_topic_arn" {
  description = "ARN create SNS topic"
  value       = var.sns_topic_arn == "" ? aws_sns_topic.this[0].arn : var.sns_topic_arn
}
