variable "user_id" {
  description = "The user ID to use in the path_part of the API Gateway resources."
  type        = string
}

variable "region" {
  description = "AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-2" 
}
