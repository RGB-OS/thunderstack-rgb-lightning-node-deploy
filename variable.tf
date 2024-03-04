# variables.tf

variable "region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2" 
}

variable "user_id" {
  description = "Unique user identifier for resource tagging and isolation"
  type        = string
}

variable "user_node_ids" {
  description = "Map of user node IDs to their respective ports"
  type = map(number)
  # Example:
  # default = {
  #   "node1" = 3001,
  #   "node2" = 3002,
  #   "node3" = 3003
  # }
}
