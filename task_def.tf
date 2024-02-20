# Create task_definition
resource "aws_ecs_task_definition" "rgb_task" {
  family                   = "rln-${var.user_id}" # Name your task
 
  container_definitions    = <<DEFINITION
  [
    {
      "name": "rln-${var.user_id}",
      "image": "${data.terraform_remote_state.vpc.outputs.rgb_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3001,
          "hostPort": 3001
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # use Fargate as the launch type
  network_mode             = "awsvpc"    # add the AWS VPN network mode as this is required for Fargate
  memory                   = 512         # Specify the memory the container requires
  cpu                      = 256         # Specify the CPU the container requires
  execution_role_arn       = "${data.terraform_remote_state.vpc.outputs`.ecsTaskExecutionRole.arn}"
}
