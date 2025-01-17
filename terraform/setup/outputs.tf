output "budget-user-access-key-id" {
  description = "AWS key ID for the budget-user"
  value       = aws_iam_access_key.budget-user.id
}

output "budget-user-access-key-secret" {
  description = "Access secret for the budget-user"
  value       = aws_iam_access_key.budget-user.secret
  sensitive   = true
}
