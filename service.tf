# Create ecs service
# Data source to refer to the existing Service Discovery namespace
data "aws_service_discovery_namespace" "existing_namespace" {
  name = "peers.thunderstack.org"
}

# Data source to refer to the existing Service Discovery service
data "aws_service_discovery_service" "existing_service" {
  name         = "lightning"
  namespace_id = data.aws_service_discovery_namespace.existing_namespace.id
}

resource "aws_ecs_service" "rgb_service" {
  for_each = var.user_node_ids
  enable_execute_command  = true
  name            = "lightning-${var.user_id}-${each.key}"     # Name the service
  cluster         = "arn:aws:ecs:us-east-2:339712759892:cluster/default"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.rgb_task[each.key].arn}" # Reference the task that the service will spin up
  launch_type     = "EC2"
  desired_count   = 1 # Set up the number of containers to 1
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[each.key].arn # Reference the target group
    container_name   = aws_ecs_task_definition.rgb_task[each.key].family
    container_port   = each.value
  }

  service_registries {
    registry_arn    = data.aws_service_discovery_service.existing_service.arn
    container_name  = aws_ecs_task_definition.rgb_task[each.key].family
    container_port  = min(65535, 9000 + tonumber(each.value))
  }
  
  tags = {
    user_id = var.user_id
    user_node_id = each.key
  }
}
