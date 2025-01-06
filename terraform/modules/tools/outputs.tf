# Output - ARN - Vault
output "vault_role_arn" {
  value = aws_iam_role.vault.arn
}
