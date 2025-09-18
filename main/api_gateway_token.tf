resource "aws_api_gateway_resource" "node_id_resource_token" {
  for_each    = var.user_node_ids
  rest_api_id = "8619bu4cli"
  parent_id   = data.terraform_remote_state.other_state.outputs.user_id_resource_token_id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy_resource_token" {
  for_each    = var.user_node_ids
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

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:339712759892:function:thunderstack-${var.env}-corsProxy/invocations"

  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each = var.user_node_ids
  statement_id  = "AllowExecutionFromAPIGateway${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = "thunderstack-${var.env}-corsProxy"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:apigateway:us-east-2::/restapis/8619bu4cli/*"
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

  depends_on = [
    aws_api_gateway_integration.cors_options_integration_token  # Ensure integration is created first
  ]
}

resource "aws_api_gateway_method" "proxy_any_method_token" {
  for_each = var.user_node_ids
  rest_api_id = "8619bu4cli"
  resource_id   = aws_api_gateway_resource.proxy_resource_token[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
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
  uri                     = "http://${var.network_load_balancer_dns}:${each.value}/{proxy}"
  connection_type         = "VPC_LINK"
  connection_id           = var.api_gateway_vpclink_id
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  depends_on = [
    aws_api_gateway_method.proxy_any_method_token  # Ensure method is created first
  ]
}
