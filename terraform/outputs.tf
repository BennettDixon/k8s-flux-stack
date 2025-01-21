output "harbor_admin_secret_arn" {
  value       = module.harbor_admin_password_secret.secret_arn
  description = "The ARN of the Secrets Manager secret for Harbor admin password"
}

output "default_harbor_docker_pull_secret_arn" {
  value       = module.default_harbor_docker_pull_secret.secret_arn
  description = "The ARN of the Secrets Manager secret for Harbor Docker pull"
}

output "example_app_harbor_docker_pull_secret_arn" {
  value       = module.example_app_harbor_docker_pull_secret.secret_arn
  description = "The ARN of the Secrets Manager secret for Harbor Docker pull"
}

output "cluster_secret_reader_iam_role_arn" {
  value       = module.cluster_secret_reader.role_arn
  description = "The ARN of the IAM role for accessing Secrets Manager"
}

output "cluster_secret_reader_iam_policy_arn" {
  value       = module.cluster_secret_reader.policy_arn
  description = "The ARN of the IAM policy attached to the IAM role"
}
