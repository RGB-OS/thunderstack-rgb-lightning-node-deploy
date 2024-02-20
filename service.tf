# Create ecs service
resource "aws_ecs_service" "rgb_service" {
  name            = "lightning-${var.user_id}"     # Name the service
  cluster         = "${data.terraform_remote_state.vpc.outputs.rgb_ecs_cluster.id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.app_task.arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Set up the number of containers to 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Reference the target group
    container_name   = "rgb-lightning-node"
    container_port   = 3001 # Specify the container port
  }

  network_configuration {
    subnets          = [data.terraform_remote_state.vpc.outputs.subnet_a.id, data.terraform_remote_state.vpc.outputs.subnet_b.id]
    assign_public_ip = true     # Provide the containers with public IPs/ can also be assign when creating subnet
    security_groups  = ["${data.terraform_remote_state.vpc.outputs.service_security_group.id}"] # Set up the security group
  }
}
