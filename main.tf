# Create a load balancer:
resource "aws_lb" "application_load_balancer" {
  name               = "lb-rgb-${var.user_id}" #load balancer name
  load_balancer_type = "application"
  subnets = [data.terraform_remote_state.vpc.outputs.subnet_a.id, data.terraform_remote_state.vpc.outputs.subnet_b.id]

  internal           = false
  # security group
  security_groups = [data.terraform_remote_state.vpc.outputs.load_balancer_security_group.id]
  tags = {
    user_id = var.user_id
  }
}

# Configure the load balancer with the VPC network
resource "aws_lb_target_group" "target_group" {
  name        = "tg-rgb-${var.user_id}"
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc.id
  tags = {
    user_id = var.user_id
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.application_load_balancer.arn}" #  load balancer
  port              = "30001"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # target group
  }
  tags = {
    user_id = var.user_id
  }
}
