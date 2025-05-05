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

  # Process events "ECS Task State Change"
  # Find more infro here https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns-content-based-filtering.html
  ecs_task_state_event_rule_detail = {
    clusterArn = [data.aws_ecs_cluster.this.arn],                  # Filter by this ECS cluster ARN,
    group      = ["service:EXAMPLE-SERVICE-NAME"]                  # and only from this ECS service,
    lastStatus = ["STOPPED"]                                       # and only when the task is stopped,
    stopCode   = [{ "anything-but" = "EssentialContainerExited" }] # but not with this stopCode
  }

  # Skip all events "ECS Deployment State Change"
  ecs_deployment_state_event_rule_detail = {}

  # Process all events "ECS Service Action"
  ecs_service_action_event_rule_detail = {
    clusterArn = [data.aws_ecs_cluster.this.arn],                     # Filter by this ECS cluster ARN,
    eventName  = [{ "anything-but" = "SERVICE_TASK_START_IMPAIRED" }] # and only with this eventName
  }

  custom_event_rules = {
    # Custom rule which triggers on all started tasks of a certain service
    ECSTaskStateChange_Started = {
      detail-type = ["ECS Task State Change"]
      source     = ["aws.ecs"]
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn],
        lastStatus = ["STARTED"]
        group      = ["service:EXAMPLE-SERVICE-NAME"]

      }
    }

    # Custom rule which triggers on all stopped tasks with non-zero exit code of the essential container
    ECSTaskStateChange_StoppedNonZero = {
      detail-type = ["ECS Task State Change"]
      source     = ["aws.ecs"]
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn],
        lastStatus = ["STOPPED"]
        stopCode   = "EssentialContainerExited"

        containers = {
          exitCode = [{ "anything-but" = 0 }]
        }
      }
    }
  }
}

module "ecs_to_slack_no_jenkins" {
  source = "../../"
  name   = "terraform-aws-eventbridge-to-amazon-q"

  ecs_task_state_event_rule_detail = {
    lastStatus    = ["STOPPED"]
    stoppedReason = [{ "anything-but" = "Stopped by Jenkins Amazon ECS PlugIn" }] # filter out jenkins ecs plugin events
  }
}
