# outputs.tf
output "invoke_urls" {
  value = { for id,value in var.user_node_ids : id => "https://cognito-node-api.thunderstack.org/nodes/${var.user_id}/${id}/" }
  description = "The invoke URLs for each node ID."
}

output "network_load_balancer_arn" {
  description = "The ARN of the Network Load Balancer"
  value       = var.network_load_balancer_arn
}

output "network_load_balancer_dns" {
  description = "The DNS name of the Network Load Balancer"
  value       = var.network_load_balancer_dns
}

output "api_gateway_vpclink_id" {
  description = "The API Gateway VPC Link ID"
  value       = var.api_gateway_vpclink_id
}
