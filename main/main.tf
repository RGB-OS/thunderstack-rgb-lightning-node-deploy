data "terraform_remote_state" "other_state" {
  backend = "s3"

  config = {
    bucket = "rln-${var.env}-terraform-backend"
    key    = "terraform_backend/${var.user_id}-shared.tfstate"
    region = "us-east-2"
  }
}

# Configure the load balancer with the VPC network
resource "aws_lb_target_group" "target_group" {
  for_each = var.user_node_ids

  name        = each.key
  port        = each.value
  protocol    = "TCP" 
  target_type = "instance"
  vpc_id      = "vpc-05c710de26ff3d5fb"

  health_check {
    enabled             = true
    protocol            = "TCP"
    interval            = 5
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  deregistration_delay  = true

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
    type         = "tg-nlb-rgb-lightning-node"
  }
}

resource "aws_lb_listener" "listener" {
  for_each = var.user_node_ids

  load_balancer_arn = var.network_load_balancer_arn
  port              = each.value
  protocol          = "TCP" 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }
}
