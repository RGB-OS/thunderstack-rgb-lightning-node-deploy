resource "aws_api_gateway_resource" "user_id_resource" {
  rest_api_id = "nvuiiz6k23"
  parent_id   = "dwpebu"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "node_id_resource" {
  for_each = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  parent_id   = aws_api_gateway_resource.user_id_resource.id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy_resource" {
  for_each = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  parent_id   = aws_api_gateway_resource.node_id_resource[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "cors_options" {
  for_each    = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  resource_id = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_options_response" {
  for_each    = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  resource_id = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "cors_options_integration" {
  for_each    = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  resource_id = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method

  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "cors_options_integration_response" {
  for_each    = var.user_node_ids
  rest_api_id = "nvuiiz6k23"
  resource_id = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = aws_api_gateway_method_response.cors_options_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "proxy_any_method" {
  for_each = var.user_node_ids
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
  for_each = var.user_node_ids
  rest_api_id             = "nvuiiz6k23"
  resource_id             = aws_api_gateway_resource.proxy_resource[each.key].id
  http_method             = aws_api_gateway_method.proxy_any_method[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri = "http://${data.terraform_remote_state.vpc.outputs.network_load_balancer_dns_name}:${each.value}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = data.terraform_remote_state.vpc.outputs.vpc_link_id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

locals {
  api_config_hash = sha1(jsonencode({
    methods      = [for method in aws_api_gateway_method.proxy_any_method : method.id],
    integrations = [for integration in aws_api_gateway_integration.nlb_integration : integration.id],
  }))
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "nvuiiz6k23"
  stage_name  = "dev"

  description = "Deployment at ${timestamp()}"

  triggers = {
    redeployment = local.api_config_hash
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy_any_method,
    aws_api_gateway_integration.nlb_integration,
  ]
}
