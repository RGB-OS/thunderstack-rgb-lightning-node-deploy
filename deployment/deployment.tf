resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.rest_api_id
  stage_name  = "dev"

  description = "Deployment at ${timestamp()}"

  lifecycle {
    create_before_destroy = true
  }
}
