# Create a load balancer:

# Configure the load balancer with the VPC network
resource "aws_lb_target_group" "target_group" {
  for_each = var.user_node_ids

  name        = each.key
  port        = each.value
  protocol    = "TCP" 
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    user_id      = var.user_id
    user_node_id = each.key
    type         = "tg-nlb-rgb-lightning-node"
  }
}

resource "aws_lb_listener" "listener" {
  for_each = var.user_node_ids

  load_balancer_arn = data.terraform_remote_state.vpc.outputs.network_load_balancer_arn
  port              = each.value
  protocol          = "TCP" 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }
}
