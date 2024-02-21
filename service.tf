# Create ecs service
resource "aws_ecs_service" "rgb_service" {
  for_each = toset(var.user_node_ids)

  name            = "lightning-${var.user_id}"     # Name the service
  cluster         = "${data.terraform_remote_state.vpc.outputs.ecs_cluster_id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.rgb_task[each.key].arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Set up the number of containers to 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group[each.key].arn # Reference the target group
    container_name   = aws_ecs_task_definition.rgb_task[each.key].family
    container_port   = 3001 # Specify the container port
  }

  network_configuration {
    subnets          = [data.terraform_remote_state.vpc.outputs.subnet_a_id, data.terraform_remote_state.vpc.outputs.subnet_b_id]
    assign_public_ip = true     # Provide the containers with public IPs/ can also be assign when creating subnet
    security_groups  = ["${data.terraform_remote_state.vpc.outputs.service_security_group_id}"] # Set up the security group
  }

  tags = {
    user_id = var.user_id
    user_node_id = each.key
  }
}
