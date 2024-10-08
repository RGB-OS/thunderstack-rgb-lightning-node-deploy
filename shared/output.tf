# outputs.tf
output "user_id_resource_mtls_id" {
  value = aws_api_gateway_resource.user_id_resource_mtls.id
}

output "user_id_resource_id" {
  value = aws_api_gateway_resource.user_id_resource.id
}

output "user_id_resource_token_id" {
  value = aws_api_gateway_resource.user_id_resource_token.id
}
