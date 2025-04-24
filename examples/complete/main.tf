terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.69.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack" {
  source = "../../"
  name   = "amazon_q_notifications"

  # Enable ECS task state change events
  enable_ecs_task_state_event_rule = true
  ecs_task_state_event_rule_detail = {
    clusterArn = ["arn:aws:ecs:us-east-1:1234567890:cluster/your-cluster-name"]
  }
}



