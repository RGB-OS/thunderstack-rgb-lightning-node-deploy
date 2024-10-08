resource "aws_api_gateway_rest_api" "api_gateway_mtls" {
  name        = "AuthorizationAPI mTLS"
  description = "API for handling requests"
}

data "aws_api_gateway_resource" "existing_resource_mtls" {
  rest_api_id = "47c4q0dr04"
  path        = var.user_id
}

resource "aws_api_gateway_resource" "user_id_resource_mtls" {
  count      = length(data.aws_api_gateway_resource.existing_resource_mtls.id) == 0 ? 1 : 0
  rest_api_id = "47c4q0dr04"
  parent_id   = "dwpebu"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "node_id_resource_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  parent_id   = aws_api_gateway_resource.user_id_resource_mtls.id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy_resource_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  parent_id   = aws_api_gateway_resource.node_id_resource_mtls[each.key].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "cors_options_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  resource_id = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_options_response_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  resource_id = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method = aws_api_gateway_method.cors_options_mtls[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "cors_options_integration_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  resource_id = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method = aws_api_gateway_method.cors_options_mtls[each.key].http_method

  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "cors_options_integration_response_mtls" {
  for_each    = var.user_node_ids
  rest_api_id = "47c4q0dr04"
  resource_id = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method = aws_api_gateway_method.cors_options_mtls[each.key].http_method
  status_code = aws_api_gateway_method_response.cors_options_response_mtls[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.cors_options_integration_mtls  # This ensures that integration is created first
  ]
}

resource "aws_api_gateway_method" "proxy_any_method_mtls" {
  for_each = var.user_node_ids
  rest_api_id   = "47c4q0dr04"
  resource_id   = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = "7aiva8"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nlb_integration_mtls" {
  for_each = var.user_node_ids
  rest_api_id             = "47c4q0dr04"
  resource_id             = aws_api_gateway_resource.proxy_resource_mtls[each.key].id
  http_method             = aws_api_gateway_method.proxy_any_method_mtls[each.key].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://vpc-link-nlb-public-1c83ff42632a54a8.elb.us-east-2.amazonaws.com:${each.value}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = "rf56qp"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [
    aws_api_gateway_method.proxy_any_method_mtls  # This ensures that the method is created first
  ]
}
