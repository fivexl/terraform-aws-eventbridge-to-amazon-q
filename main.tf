locals {
  # Create a result map of all built-in event rules and given custom rules.
  event_rules = merge(
    var.enable_ecs_task_state_event_rule ? {
      ECSTaskStateChange = {
        detail-type = ["ECS Task State Change"]
        detail      = var.ecs_task_state_event_rule_detail
        source      = ["aws.ecs"]
      }
    } : {},
    var.enable_ecs_deployment_state_event_rule ? {
      ECSDeploymentStateChange = {
        detail-type = ["ECS Deployment State Change"]
        detail      = var.ecs_deployment_state_event_rule_detail
        source      = ["aws.ecs"]
      }
    } : {},
    var.enable_ecs_service_action_event_rule ? {
      ECSServiceAction = {
        detail-type = ["ECS Service Action"]
        detail      = var.ecs_service_action_event_rule_detail
        source      = ["aws.ecs"]
      }
    } : {},
    var.custom_event_rules
  )
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.event_rules

  name        = "${var.name}-${each.key}"
  description = "Event rule for ${each.key}"
  event_pattern = jsonencode({
    source      = each.value.source
    detail-type = each.value.detail-type
    detail      = each.value.detail
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.event_rules

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "${var.name}-${each.key}"
  arn       = var.sns_topic_arn != "" ? var.sns_topic_arn : aws_sns_topic.this[0].arn

  dynamic "input_transformer" {
    for_each = try(each.value.input_transformer != null ? [each.value.input_transformer] : [], [])
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}




