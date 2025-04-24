locals {
  # Create a result map of all built-in event rules and given custom rules.
  event_rules = merge(
    var.enable_ecs_task_state_event_rule ? {
      ECSTaskStateChange = {
        detail-type = ["ECS Task State Change"]
        detail      = var.ecs_task_state_event_rule_detail
      }
    } : {},
    var.enable_ecs_deployment_state_event_rule ? {
      ECSDeploymentStateChange = {
        detail-type = ["ECS Deployment State Change"]
        detail      = var.ecs_deployment_state_event_rule_detail
      }
    } : {},
    var.enable_ecs_service_action_event_rule ? {
      ECSServiceAction = {
        detail-type = ["ECS Service Action"]
        detail      = var.ecs_service_action_event_rule_detail
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
    source      = [try(each.value.source, "aws.ecs")]
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
    for_each = each.key == "ECSTaskStateChange" ? [1] : []
    content {
      input_paths = {
        "account"              = "$.account"
        "detail"               = "$.detail"
        "detail-type"          = "$.detail-type"
        "id"                   = "$.id"
        "region"               = "$.region"
        "resources"            = "$.resources"
        "time"                 = "$.time"
        "taskDefinitionArn"    = "$.detail.taskDefinitionArn"
        "lastStatus"           = "$.detail.lastStatus"
        "desiredStatus"        = "$.detail.desiredStatus"
        "containerInstanceArn" = "$.detail.containerInstanceArn"
        "healthStatus"         = "$.detail.healthStatus"
        "stopCode"             = "$.detail.stopCode"
        "stoppedReason"        = "$.detail.stoppedReason"
        "containers"           = "$.detail.containers"
      }
      input_template = <<EOF
{
  "version": "1.0",
  "source": "custom",
  "id": <id>,
  "content": {
    "textType": "client-markdown",
    "title": <detail-type>,
    "description": "*Event Detail:* \r\n• Task Definition: <taskDefinitionArn>\r\n• Last: <lastStatus>\r\n• Desired: <desiredStatus> \r\n• account: <account> \r\n• time: <time>",
    "keywords": [<region>]
  },
  "metadata": {
    "threadId": <id>,
    "summary": <detail-type>,
    "eventType": <detail-type>,
    "relatedResources": <resources>,
    "additionalContext": {
      "account": <account>,
      "time": <time>
    }
  }
}
EOF
    }
  }

  dynamic "input_transformer" {
    for_each = each.key == "ECSDeploymentStateChange" ? [1] : []
    content {
      input_paths = {
        "account"      = "$.account"
        "detail"       = "$.detail"
        "detail-type"  = "$.detail-type"
        "id"           = "$.id"
        "region"       = "$.region"
        "resources"    = "$.resources"
        "time"         = "$.time"
        "eventType"    = "$.detail.eventType"
        "eventName"    = "$.detail.eventName"
        "deploymentId" = "$.detail.deploymentId"
        "reason"       = "$.detail.reason"
      }
      input_template = <<EOF
{
  "version": "1.0",
  "source": "custom",
  "id": <id>,
  "content": {
    "textType": "client-markdown",
    "title": <detail-type>,
    "description": "*Event Detail:* \r\n• <eventType> - <eventName>\r\n• Deployment: <deploymentId>\r\n• Reason: <reason> \r\n• account: <account> \r\n• time: <time>",
    "keywords": [<region>]
  },
  "metadata": {
    "threadId": <id>,
    "summary": <detail-type>,
    "eventType": <detail-type>,
    "relatedResources": <resources>,
    "additionalContext": {
      "account": <account>,
      "time": <time>
    }
  }
}
EOF
    }
  }

  dynamic "input_transformer" {
    for_each = each.key == "ECSServiceAction" ? [1] : []
    content {
      input_paths = {
        "account"     = "$.account"
        "detail"      = "$.detail"
        "detail-type" = "$.detail-type"
        "id"          = "$.id"
        "region"      = "$.region"
        "resources"   = "$.resources"
        "time"        = "$.time"
        "eventType"   = "$.detail.eventType"
        "eventName"   = "$.detail.eventName"
      }
      input_template = <<EOF
{
  "version": "1.0",
  "source": "custom",
  "id": <id>,
  "content": {
    "textType": "client-markdown",
    "title": <detail-type>,
    "description": "*Event Detail:* \r\n• <eventType> - <eventName> \r\n• account: <account> \r\n• time: <time>",
    "keywords": [<region>]
  },
  "metadata": {
    "threadId": <id>,
    "summary": <detail-type>,
    "eventType": <detail-type>,
    "relatedResources": <resources>,
    "additionalContext": {
      "account": <account>,
      "time": <time>
    }
  }
}
EOF
    }
  }
}




