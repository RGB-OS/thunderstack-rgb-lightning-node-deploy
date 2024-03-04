# outputs.tf
output "invoke_urls" {
  value = { for id,value in var.user_node_ids : id => "${aws_api_gateway_deployment.deployment.invoke_url}/nodes/${var.user_id}/${id}/" }
  description = "The invoke URLs for each node ID."
}
