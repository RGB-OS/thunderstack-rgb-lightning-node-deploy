resource "aws_api_gateway_deployment" "deployment_1" {
  rest_api_id = "8619bu4cli"
  stage_name  = "dev"
  
  description = "Deployment at ${timestamp()}"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "deployment_2" {
  rest_api_id = "47c4q0dr04"
  stage_name  = "dev"
  
  description = "Deployment at ${timestamp()}"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "deployment_3" {
  rest_api_id = "nvuiiz6k23"
  stage_name  = "dev"
  
  description = "Deployment at ${timestamp()}"
  
  lifecycle {
    create_before_destroy = true
  }
}
