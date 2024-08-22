resource "aws_ebs_volume" "task_volume" {
  for_each = var.user_node_ids

  availability_zone = "${var.region}a"
  size              = 10
  type              = "gp2"
  tags = {
    Name = "rln-ebs-${var.user_id}-${each.key}"
  }
}

resource "null_resource" "detach_volume" {
  for_each = var.user_node_ids

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      VOLUME_ID=$(aws ec2 describe-volumes --filters Name=tag:Name,Values=self.${self.triggers.volume_name} --query "Volumes[0].VolumeId" --output text)
      if aws ec2 describe-volumes --volume-ids $VOLUME_ID | grep -q "InstanceId"; then
        aws ec2 detach-volume --volume-id $VOLUME_ID
      fi
    EOT
  }

  triggers = {
    volume_name = "rln-ebs-${var.user_id}-${each.key}"
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
                "${var.btc_rpc}",
                "/dataldk0/",
                "--daemon-listening-port",
                tostring(each.value),
                "--ldk-peer-listening-port",
                tostring(min(65535, 9000 + tonumber(each.value))),
                "--network",
                "${var.btc_network}"
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
      memory       = 512,
      cpu          = 512,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/rln-${var.user_id}-${each.key}"
          awslogs-region        = "us-east-2", 
          awslogs-stream-prefix = "ecs", 
          awslogs-create-group  = "true"
        }
      },
      mountPoints = [
        {
          sourceVolume  = "host_volume"
          containerPath = "/mnt"
          readOnly      = false
        }
      ]
    }
  ])

  volume {
    name = "host_volume"
    host_path = "/mnt"
  }

  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  memory                   = 512
  cpu                      = 512
  execution_role_arn       = "${data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn}"
  task_role_arn            = "${data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn}"

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
  }
}
