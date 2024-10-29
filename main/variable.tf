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

variable "btc_rpc" {
  description = "user:password@HOSTNAME:PORT"
  type        = string
}

variable "btc_network" {
  description = "BTC Network (mainnet,testnet,regrest)"
  type        = string
}

variable "env" {
  description = "Thanderstack enviroment type (test/prod)"
  type        = string
}

variable "cognito_authorizer_id" {
  description = "Cognito authorizer ID"
  type        = string
}

variable "token_authorizer_id" {
  description = "Token authorizer ID"
  type        = string
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
}

variable "docker_healthcheck_image_tag" {
  description = "Healthcheck docker image tag"
  type        = string
}

variable "ecr_healthcheck_repository_url" {
  description = "Healthcheck docker image repo"
  type        = string
}

variable "network_load_balancer_arn" {
  description = "Network Load Balancer ARN"
  type        = string
}

variable "network_load_balancer_url" {
  description = "Network Load Balancer URL"
  type        = string
}

variable "api_gateway_vpclink_id" {
  description = "API Gateway VPC Link ID"
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
