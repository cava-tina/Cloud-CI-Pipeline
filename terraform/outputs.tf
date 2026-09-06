output "reports_bucket" {
  value = aws_s3_bucket.paylite_reports.bucket
}

# Remediated Finding #6: Removed svc_deploy_secret_access_key output to prevent plain-text log leakage.

output "db_endpoint" {
  value = aws_db_instance.paylite_db.endpoint
}
