# VPC Flow Logs setup
resource "aws_flow_log" "vpc_flow_logs" {
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  tags = merge(local.common_tags, {
    Name = "vpc-flow-logs"
  })
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = merge(local.common_tags, {
    Name = "vpc-flow-logs"
  })
}

# KMS key for VPC Flow Logs encryption
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
        Sid    = "Allow CloudWatch to use the key"
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

  tags = merge(local.common_tags, {
    Name = "${var.environment}-flow-logs-encryption"
  })
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/${var.environment}-flow-logs"
  target_key_id = aws_kms_key.flow_logs.key_id
}

# Main VPC Security Group
resource "aws_security_group" "main_vpc_sg" {
  name        = "main-vpc-sg"
  description = "Main security group for VPC traffic"
  vpc_id      = aws_vpc.main.id

  # HTTP from allowed IPs
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "HTTP from allowed IPs"
  }

  # HTTPS from allowed IPs
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
    description = "HTTPS from allowed IPs"
  }

  # SSH from VPC only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_configuration.cidr]
    description = "SSH from VPC only"
  }

  # Required outbound rules
  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  egress {
    from_port = 53
    to_port   = 53
    protocol  = "udp"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = merge(local.common_tags, {
    Name = "main-vpc-sg"
    Type = "vpc-security"
  })
}
