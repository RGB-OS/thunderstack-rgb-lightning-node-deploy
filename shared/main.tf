resource "aws_api_gateway_resource" "user_id_resource_mtls" {
  rest_api_id = "47c4q0dr04"
  parent_id   = "dwpebu"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "user_id_resource" {
  rest_api_id = "nvuiiz6k23"
  parent_id   = "dwpebu"
  path_part   = "${var.user_id}"
}

resource "aws_api_gateway_resource" "user_id_resource_token" {
  rest_api_id = "8619bu4cli"
  parent_id   = "l97dl58la4"
  path_part   = "${var.user_id}"
}

