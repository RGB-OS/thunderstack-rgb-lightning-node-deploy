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
  description = "Unique user identifiers for resource tagging and isolation"
  type        = list
}
