data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Flow Logs for VPC
resource "aws_flow_log" "vpc_flow_logs" {
  # Log ALL traffic - accepted and rejected
  traffic_type = "ALL"

  # Log into CloudWatch
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn

  vpc_id = aws_vpc.main.id

  # IAM Role for Logging
  iam_role_arn = aws_iam_role.vpc_flow_logs.arn
}

# Log Group in CloudWatch
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 30                        # Keep 30 Days
  kms_key_id        = aws_kms_key.flow_logs.arn # Encryption
}

# VPC Flow Logs KMS Key
resource "aws_kms_key" "flow_logs" {
  description             = "${var.environment} VPC Flow Logs Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM Root User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow VPC Flow Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-flow-logs-encryption"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/${var.environment}-flow-logs"
  target_key_id = aws_kms_key.flow_logs.key_id
}

# IAM Role for Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

# Allow writing logs to CloudWatch
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.flow_logs.arn
      }
    ]
  })
}
