resource "aws_ebs_volume" "task_volume" {
  for_each = var.user_node_ids

  availability_zone = "${var.region}a"
  size              = 10
  type              = "gp2"
  tags = {
    Name = "rln-ebs-${var.user_id}-${each.key}"
  }
}

resource "aws_ecs_task_definition" "rgb_task" {
  for_each = var.user_node_ids

  family = "rln-${var.user_id}"
  container_definitions = jsonencode([
    {
      name         = "rln-${var.user_id}",
      image        = "${data.terraform_remote_state.vpc.outputs.ecr_repository_url}:${var.docker_image_tag}",
      essential    = true,
      privileged   = true,
      command      = [
        "rln-backups",
        aws_ebs_volume.task_volume[each.key].id,
        "${var.user_id}",
        each.key,
        "/mnt/ebs-${var.user_id}-${each.key}",
        "--daemon-listening-port",
        tostring(each.value),
        "--ldk-peer-listening-port",
        tostring(min(65535, 9000 + tonumber(each.value))),
        "--network",
        "${var.btc_network}",
        "--root-public-key ${var.biscuit_root_pubkey}"
      ],
      portMappings = [
        {
          containerPort = each.value,
          hostPort      = each.value
        },
        {
          containerPort = min(65535, 9000 + tonumber(each.value)),
          hostPort      = min(65535, 9000 + tonumber(each.value))
        }
      ],
      memory       = 768,
      cpu          = 448,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/rln-${var.user_id}-${each.key}",
          awslogs-region        = "us-east-2", 
          awslogs-stream-prefix = "ecs", 
          awslogs-create-group  = "true"
        }
      },
      mountPoints = [
        {
          sourceVolume  = "host_volume",
          containerPath = "/mnt",
          readOnly      = false
        },
        {
          sourceVolume  = "host_dev_volume",
          containerPath = "/dev",
          readOnly      = false
        }
      ]
    },
    {
      name = "health-check-sidecar",
      image = "${var.ecr_healthcheck_repository_url}:${var.docker_healthcheck_image_tag}",
      essential = false,
      links        = ["rln-${var.user_id}"],
      portMappings = [
        {
          containerPort = min(65535, 36000 + tonumber(each.value)),
          hostPort      = min(65535, 36000 + tonumber(each.value))
        }
      ],
      memory       = 128,
      cpu          = 64
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/rln-${var.user_id}-${each.key}",
          awslogs-region        = "us-east-2", 
          awslogs-stream-prefix = "ecs", 
          awslogs-create-group  = "true"
        }
      },
      command = ["-c", "python /app/healthcheck.py ${tostring(each.value)} ${min(65535, 36000 + tonumber(each.value))} rln-${var.user_id}"]
    }
  ])

  volume {
    name      = "host_volume"
    host_path = "/mnt"
  }

  volume {
    name      = "host_dev_volume"
    host_path = "/dev"
  }

  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  memory                   = 896
  cpu                      = 512
  execution_role_arn       = "${data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn}"
  task_role_arn            = "${data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn}"

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
    PUBLICHOSTEDZONE = "peers.thunderstack.org"
    HOSTEDZONEID = "Z0517355Z7RBMRE6ARC9"
  }
}
