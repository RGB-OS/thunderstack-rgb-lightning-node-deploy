# Create ecs service
resource "aws_service_discovery_service" "rgb_service_discovery" {
  for_each = var.user_node_ids
  name         = each.key
  namespace_id = "ns-33wm445xihjw7y7f"

  dns_config {
    namespace_id   = "ns-33wm445xihjw7y7f"
    routing_policy = "MULTIVALUE"
    dns_records {
      type = "SRV"
      ttl  = 3600
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "rgb_service" {
  for_each = var.user_node_ids
  enable_execute_command = true
  name                   = each.key
  cluster                = "arn:aws:ecs:us-east-2:339712759892:cluster/default"
  task_definition        = aws_ecs_task_definition.rgb_task[each.key].arn
  launch_type            = "EC2"
  desired_count          = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
    container_name   = aws_ecs_task_definition.rgb_task[each.key].family
    container_port   = each.value
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.rgb_service_discovery[each.key].arn
    container_name = aws_ecs_task_definition.rgb_task[each.key].family
    container_port = min(65535, 9000 + tonumber(each.value))
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
    PUBLICHOSTEDZONE = "peers.thunderstack.org"
    HOSTEDZONEID     = "Z0517355Z7RBMRE6ARC9"
  }
}
