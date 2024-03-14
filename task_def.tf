resource "aws_ecs_task_definition" "rgb_task" {
  for_each = var.user_node_ids

  family = "rln-${var.user_id}"

  container_definitions = jsonencode([
    {
      name         = "rln-${var.user_id}",
      image        = "${data.terraform_remote_state.vpc.outputs.ecr_repository_url}",
      essential    = true,
      command      = [
                "rln-backups",
                "user:password@18.119.98.232:18443",
                "/dataldk0/",
                "--daemon-listening-port",
                tostring(each.value),
                "--ldk-peer-listening-port",
                "9735",
                "--network",
                "regtest"
            ]
      portMappings = [
        {
          containerPort = each.value,
          hostPort      = each.value
        },
        {
          containerPort = 9735, 
          hostPort      = 9735
        }
      ],
      memory       = 512,
      cpu          = 256,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/rln-${var.user_id}-${each.key}"
          awslogs-region        = "us-east-2", 
          awslogs-stream-prefix = "ecs", 
          awslogs-create-group  = "true"
        }
      }
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = "${data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn}"

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
  }
}
