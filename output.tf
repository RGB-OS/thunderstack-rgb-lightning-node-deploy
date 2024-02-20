# outputs.tf

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.my_cluster.arn
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.application_load_balancer.arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecsTaskExecutionRole.arn
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app_service.id
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app_task.arn
}
