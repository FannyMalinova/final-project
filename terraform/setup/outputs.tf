####################
# Output values for budget-user AWS login credentials.
####################

output "budget-user-access-key-id" {
  description = "AWS key ID for the budget-user"
  value       = aws_iam_access_key.budget-user.id
}

output "budget-user-access-key-secret" {
  description = "Access secret for the budget-user"
  value       = aws_iam_access_key.budget-user.secret
  sensitive   = true
}

#####################
# Output URLs for the ECR repository.
#####################

output "ecr-repo-budget-app" {
  description = "URL of the ECR repository for the budget app container image"
  value       = aws_ecr_repository.budget-app-repo.repository_url
}
