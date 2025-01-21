module "harbor_admin_password_secret" {
  source       = "./modules/secrets_manager"
  secret_name  = "k3s_harbor_admin_password"
  description  = "Admin password for Harbor dashboard"
  secret_value = var.harbor_admin_password
}

module "default_harbor_docker_pull_secret" {
  source = "./modules/secrets_manager"
  secret_name = "k3s_harbor_docker_pull_default"
  description = "Default registry login info for Harbor"
  secret_value = jsonencode({
    username = var.default_harbor_docker_pull_username
    password = var.default_harbor_docker_pull_password
    email = var.default_harbor_docker_pull_email
    registry = var.harbor_registry_domain
  })
}

module "example_app_harbor_docker_pull_secret" {
  source = "./modules/secrets_manager"
  secret_name = "k3s_harbor_docker_pull_example_app"
  description = "Example app registry login info for Harbor"
  secret_value = jsonencode({
    username = var.example_app_harbor_docker_pull_username
    password = var.example_app_harbor_docker_pull_password
    email = var.example_app_harbor_docker_pull_email
    registry = var.harbor_registry_domain
  })
}

module "cluster_secret_reader" {
  source       = "./modules/iam"
  role_name    = "k3s-cluster-secrets-access-role"
  service_name = "ecs-tasks.amazonaws.com"
  policy_name  = "k3s-cluster-secrets-access-policy"
  policy_json  = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = [
          module.harbor_admin_password_secret.secret_arn,
          module.default_harbor_docker_pull_secret.secret_arn,
          module.example_app_harbor_docker_pull_secret.secret_arn
        ]
      }
    ]
  })
}
