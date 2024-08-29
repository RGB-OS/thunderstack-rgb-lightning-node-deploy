# outputs.tf
output "invoke_urls" {
  value = { for id,value in var.user_node_ids : id => "https://cognito-node-api.thunderstack.org/nodes/${var.user_id}/${id}/" }
  description = "The invoke URLs for each node ID."
}
