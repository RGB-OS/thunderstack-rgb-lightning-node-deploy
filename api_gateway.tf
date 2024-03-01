resource "aws_api_gateway_vpc_link" "node_vpc_link" {
  for_each = toset(var.user_node_ids)
  name        = "vpc-link-${var.user_id}"
  description = "VPC link for our microservices"
  target_arns = [aws_lb.network_load_balancer[each.key].arn]
}

resource "aws_api_gateway_resource" "user_id_resource" {
  rest_api_id = "nvuiiz6k23"
  parent_id   = "dwpebu"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "node_id_resource" {
  for_each = toset(var.user_node_ids)
  rest_api_id = "nvuiiz6k23"
  parent_id   = aws_api_gateway_resource.user_id_resource.id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy_resource" {
  for_each = toset(var.user_node_ids)
  rest_api_id = "nvuiiz6k23"
  parent_id   = aws_api_gateway_resource.node_id_resource[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any_method" {
  for_each = toset(var.user_node_ids)
  rest_api_id   = "nvuiiz6k23"
  resource_id   = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = "9ge7s1"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nlb_integration" {
  for_each = toset(var.user_node_ids)
  rest_api_id             = "nvuiiz6k23"
  resource_id             = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method             = aws_api_gateway_method.proxy_any_method[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri = "http://${aws_lb.network_load_balancer[each.key].dns_name}:3001/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.node_vpc_link[each.key].id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  for_each = toset(var.user_node_ids)
  rest_api_id = "nvuiiz6k23"
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.nlb_integration[each.key].id))
  }

  lifecycle {
    create_before_destroy = true
  }
}

