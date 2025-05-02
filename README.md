[![FivexL](https://releases.fivexl.io/fivexlbannergit.jpg)](https://fivexl.io/)

# terraform-aws-ecs-events-to-slack

This module helps you to send AWS EventBrige events to Slack / Microsoft teams 

## Description

This module creates EventBridge rules `aws_cloudwatch_event_rule` that:
1. Capture ECS events
2. Send them to a specified SNS topic

The SNS topic sends messages to Amazon Q Developer, which then distributes them to:
- Slack

- Microsoft Teams

## Supported ECS Events

- ECS Task State Changes
- ECS Deployment State Changes
- ECS Service Actions

## Usage Example

```hcl
module "ecs_to_slack" {
  source = "../terraform-aws-ecs-events-to-slack"
  name   = "amazon_q_notifications"

  # Enable ECS task state change events
  enable_ecs_task_state_event_rule = true

  # Filter events for specific ECS cluster
  ecs_task_state_event_rule_detail = {
    clusterArn = ["arn:aws:ecs:us-east-1:123456789012:your-cluster/services"]
  }

  # Optional: Provide existing SNS topic ARN
  # If not provided, module will create a new SNS topic
  sns_topic_arn = "arn:aws:sns:region:account-id:topic-name"

  # Optional: Provide custom KMS key for SNS topic encryption
  # If not provided, SNS topic will not use encryption.
  # Note: To enable encryption and manage access permissions, you must provide your own KMS/CMK key.
  kms_master_key_id = "arn:aws:kms:region:account-id:key/key-id"
}
```

## Prerequisites

1. Amazon Q Developer workspace must be configured and accessible
2. Chat bot must be subscribed to the SNS topic configuration

> Note: AWS managed service keys don't allow you to modify access policies, so you will need AWS KMS/CMK for encrypted SNS topics. You can then update the access permissions in the AWS KMS key policy to allow the service that sends messages to publish to your encrypted SNS topics (for example, EventBridge).

3. If using existing SNS topic, ensure it has proper permissions for EventBridge to publish messages

## Important Notes

- The module can create a new SNS topic if `sns_topic_arn` is not provided
- If you provide an existing SNS topic, ensure it has the correct permissions and encryption settings
- Chat bot must be properly configured in your Amazon Q Developer workspace to receive notifications
- Make sure to subscribe your chat bot to the SNS topic configuration after deployment

## Message Format

The module sends events in the following format that is compatible with Amazon Q Developer:

```json
{
  "version": "1.0",
  "source": "custom",
  "id": "<event_id>",
  "content": {
    "textType": "client-markdown",
    "title": "<event_type>",
    "description": "<formatted_message>",
    "keywords": ["<region>"]
  },
  "metadata": {
    "threadId": "<event_id>",
    "summary": "<event_type>",
    "eventType": "<event_type>",
    "relatedResources": ["<resource_arns>"],
    "additionalContext": {
      "account": "<aws_account>",
      "time": "<event_time>"
    }
  }
}
```

## Additional Information

- [ECS Events Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html)
- [EventBridge Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
- [EventBridge Input Transformation](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-transform-target-input.html)
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/chatbot/latest/adminguide/what-is-chatbot.html)

## KMS Key Policy Example for Encrypted SNS Topics

If you use a custom KMS key for SNS topic encryption, you must add the following statement to your KMS key policy to allow EventBridge (CloudWatch Events) to publish to the encrypted SNS topic:

```json
{
  "Sid": "Allow CWE to use the key",
  "Effect": "Allow",
  "Principal": {
    "Service": "events.amazonaws.com"
  },
  "Action": [
    "kms:Decrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "*"
}
```

This allows EventBridge to generate data keys and decrypt messages for publishing to the encrypted SNS topic. Without this policy, EventBridge will not be able to send events to your encrypted SNS topic.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 5.61.0 |

## Providers

| Name                                              | Version   |
| ------------------------------------------------- | --------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                    | Type     |
| --------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)     | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)                             | resource |
| [aws_sns_topic_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy)               | resource |

## Inputs

| Name                                                                                                                                                           | Description                                                                                                                                                                                     | Type          | Default                                                                                                                                                                                                                                     | Required |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_custom_event_rules"></a> [custom\_event\_rules](#input\_custom\_event\_rules)                                                                   | A map of objects representing the custom EventBridge rule which will be created in addition to the default rules.                                                                               | `map(any)`    | `{}`                                                                                                                                                                                                                                        |    no    |
| <a name="input_ecs_deployment_state_event_rule_detail"></a> [ecs\_deployment\_state\_event\_rule\_detail](#input\_ecs\_deployment\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack.                     | `any`         | <pre>{<br/>  "eventType": [<br/>    "ERROR"<br/>  ]<br/>}</pre>                                                                                                                                                                             |    no    |
| <a name="input_ecs_service_action_event_rule_detail"></a> [ecs\_service\_action\_event\_rule\_detail](#input\_ecs\_service\_action\_event\_rule\_detail)       | The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack.                              | `any`         | <pre>{<br/>  "eventType": [<br/>    "WARN",<br/>    "ERROR"<br/>  ]<br/>}</pre>                                                                                                                                                             |    no    |
| <a name="input_ecs_task_state_event_rule_detail"></a> [ecs\_task\_state\_event\_rule\_detail](#input\_ecs\_task\_state\_event\_rule\_detail)                   | The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack.                           | `any`         | <pre>{<br/>  "lastStatus": [<br/>    "STOPPED"<br/>  ],<br/>  "stoppedReason": [<br/>    {<br/>      "anything-but": {<br/>        "prefix": "Scaling activity initiated by (deployment ecs-svc/"<br/>      }<br/>    }<br/>  ]<br/>}</pre> |    no    |
| <a name="input_enable_ecs_deployment_state_event_rule"></a> [enable\_ecs\_deployment\_state\_event\_rule](#input\_enable\_ecs\_deployment\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Deployment State Change` events. The `detail` section of this rule is configured with `ecs_deployment_state_event_rule_detail` variable. | `bool`        | `true`                                                                                                                                                                                                                                      |    no    |
| <a name="input_enable_ecs_service_action_event_rule"></a> [enable\_ecs\_service\_action\_event\_rule](#input\_enable\_ecs\_service\_action\_event\_rule)       | The boolean flag enabling the EvenBridge Rule for `ECS Service Action` events. The `detail` section of this rule is configured with `ecs_service_action_event_rule_detail` variable.            | `bool`        | `true`                                                                                                                                                                                                                                      |    no    |
| <a name="input_enable_ecs_task_state_event_rule"></a> [enable\_ecs\_task\_state\_event\_rule](#input\_enable\_ecs\_task\_state\_event\_rule)                   | The boolean flag enabling the EvenBridge Rule for `ECS Task State Change` events. The `detail` section of this rule is configured with `ecs_task_state_event_rule_detail` variable.             | `bool`        | `true`                                                                                                                                                                                                                                      |    no    |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id)                                                                    | The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. If not provided, will use default AWS SNS key                                                                | `string`      | `""`                                                                                                                                                                                                                                        |    no    |
| <a name="input_name"></a> [name](#input\_name)                                                                                                                 | Name to be used on all the resources as identifier                                                                                                                                              | `string`      | `"aws-eventbridge-to-amazon-q-developer"`                                                                                                                                                                                                   |    no    |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn)                                                                                  | The ARN of the SNS topic used for notifications, If not provided, topic will create SNS topic it self                                                                                           | `string`      | `""`                                                                                                                                                                                                                                        |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                                 | A map of tags to add to all resources                                                                                                                                                           | `map(string)` | `{}`                                                                                                                                                                                                                                        |    no    |

## Outputs

| Name                                                                            | Description          |
| ------------------------------------------------------------------------------- | -------------------- |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN create SNS topic |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


