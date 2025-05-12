terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

data "aws_ecs_cluster" "this" {
  cluster_name = "EXAMPLE-CLUSTER-NAME"
}

module "ecs_to_slack" {
  source = "../../"
  name   = "terraform-aws-eventbridge-to-amazon-q"

  # Do not create any built-in rule

  enable_ecs_task_state_event_rule       = false
  enable_ecs_deployment_state_event_rule = false
  enable_ecs_service_action_event_rule   = false

  # Create a custom rule, for all events from the cluster's Container Instances
  # Find more infro here https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns-content-based-filtering.html
  custom_event_rules = {
    ECSContInstanceStateChange = {
      detail-type = ["ECS Container Instance State Change"]
      source      = ["aws.ecs"]
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn], # Filter by this ECS cluster ARN,
        status     = [{ "anything-but" = "ACTIVE" }]  # except events with status = ACTIVE

      }
    }
  }
}
