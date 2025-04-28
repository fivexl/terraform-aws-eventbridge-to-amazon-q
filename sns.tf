resource "aws_sns_topic" "this" {
  count             = var.sns_topic_arn == "" ? 1 : 0
  name              = var.name
  tags              = var.tags
  kms_master_key_id = var.kms_master_key_id != "" ? var.kms_master_key_id : "alias/aws/sns"
}

resource "aws_sns_topic_policy" "this" {
  count = var.sns_topic_arn == "" ? 1 : 0
  arn   = aws_sns_topic.this[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this[0].arn
      }
    ]
  })
}
