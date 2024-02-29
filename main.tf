# Create a load balancer:
resource "aws_lb" "application_load_balancer" {
  for_each = toset(var.user_node_ids)

  name               = each.key #load balancer name
  load_balancer_type = "application"
  subnets = [data.terraform_remote_state.vpc.outputs.subnet_a_id, data.terraform_remote_state.vpc.outputs.subnet_b_id]

  internal           = false
  # security group
  security_groups = [data.terraform_remote_state.vpc.outputs.load_balancer_security_group_id]
  tags = {
    user_id = var.user_id
    user_node_id = each.key
    type = "alb-rgb-lightning-node"
  }
}

# Configure the load balancer with the VPC network
resource "aws_lb_target_group" "target_group" {
  for_each = toset(var.user_node_ids)

  name        = each.key
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    enabled             = true
    path                = "/nodeinfo"
    protocol            = "HTTP"
    matcher             = "200,403"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    user_id = var.user_id
    user_node_id = each.key
    type = "tg-rgb-lightning-node"
  }
}

resource "aws_lb_listener" "listener" {
  for_each = toset(var.user_node_ids)

  load_balancer_arn = "${aws_lb.application_load_balancer[each.key].arn}" #  load balancer
  port              = "3001"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group[each.key].arn}" # target group
  }
  tags = {
    user_id = var.user_id
    user_node_id = each.key
  }
}
