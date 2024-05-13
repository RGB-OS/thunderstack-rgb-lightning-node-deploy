resource "aws_api_gateway_resource" "user_id_resource_token" {
  rest_api_id = "8619bu4cli"
  parent_id   = "l97dl58la4"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "node_id_resource_token" {
  for_each = var.user_node_ids
  rest_api_id = "8619bu4cli"
  parent_id   = aws_api_gateway_resource.user_id_resource_token.id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy_resource_token" {
  for_each = var.user_node_ids
  rest_api_id = "8619bu4cli"
  parent_id   = aws_api_gateway_resource.node_id_resource_token[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "cors_options_token" {
  for_each    = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_options_response_token" {
  for_each    = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method = aws_api_gateway_method.cors_options_token[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "cors_options_integration_token" {
  for_each    = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method = aws_api_gateway_method.cors_options_token[each.key].http_method

  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "cors_options_integration_response_token" {
  for_each    = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method = aws_api_gateway_method.cors_options_token[each.key].http_method
  status_code = aws_api_gateway_method_response.cors_options_response_token[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "proxy_any_method_token" {
  for_each = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id   = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = "9rfqdx"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nlb_integration_token" {
  for_each = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id             = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method             = aws_api_gateway_method.proxy_any_method_token[each.key].http_method
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
  api_config_hash_token = sha1(jsonencode({
    methods      = [for method in aws_api_gateway_method.proxy_any_method_token : method.id],
    integrations = [for integration in aws_api_gateway_integration.nlb_integration_token : integration.id],
  }))
}

resource "aws_api_gateway_deployment" "deployment_token" {
  rest_api_id = "8619bu4cli"
  stage_name  = "dev"

  description = "Deployment at ${timestamp()}"

  triggers = {
    redeployment = local.api_config_hash_token
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.proxy_any_method_token,
    aws_api_gateway_integration.nlb_integration_token,
    aws_api_gateway_integration.cors_options_integration_token
  ]
}
