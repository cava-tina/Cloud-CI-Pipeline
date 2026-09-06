# paylite — internal payments reconciliation app (fictional)
# Infra: one app bucket, one service user, one app security group, one MySQL RDS.

provider "aws" {
  region = "ap-southeast-1"
  # Finding #1 Remediation: Hardcoded access keys removed.
  # Terraform automatically falls back to runtime environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
}

resource "aws_s3_bucket" "paylite_reports" {
  bucket        = "paylite-recon-reports"
  force_destroy = false
}

# Finding #3 Remediation: Enforce S3 Block Public Access to prevent data leaks
resource "aws_s3_bucket_public_access_block" "paylite_reports_block" {
  bucket                  = aws_s3_bucket.paylite_reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_user" "svc_deploy" {
  name = "svc-paylite-deploy"
}

# Finding #2 Remediation: Least-privilege IAM user policy scoping down permissions
resource "aws_iam_user_policy" "svc_deploy_policy" {
  name = "svc-paylite-deploy-policy"
  user = aws_iam_user.svc_deploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.paylite_reports.arn,
          "${aws_s3_bucket.paylite_reports.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "svc_deploy_key" {
  user = aws_iam_user.svc_deploy.name
}

resource "aws_security_group" "paylite_app" {
  name = "paylite-app-sg"
  description = "paylite app access restricted to corporate VPN and internal application subnets"

  # Finding #4 Remediation: Restricted SSH ingress to corporate VPN static IP
  ingress {
    description = "ssh-vpn-access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.50/32"]
  }

  # Finding #4 Remediation: Restricted MySQL ingress exclusively to internal VPC subnets
  ingress {
    description = "mysql-internal-vpc"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow outbound traffic for patches and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "paylite_db" {
  identifier                = "paylite-db"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t3.medium"
  allocated_storage         = 50
  username                  = "admin"
  password                  = var.db_password
  publicly_accessible       = false # Finding #5 Remediation: Isolated database in private subnets
  storage_encrypted         = true  # Finding #5 Remediation: Enabled storage encryption at rest
  skip_final_snapshot       = false
  final_snapshot_identifier = "paylite-db-final-snapshot"
  vpc_security_group_ids    = [aws_security_group.paylite_app.id]
  auto_minor_version_upgrade    = true  # Included this line to ensure minor versions are also upgraded to prevent potential zero day attacks 
  deletion_protection           = true

}