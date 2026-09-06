# G2G Cloud Security & DevOps — Take-Home Starter Kit

Read the candidate brief (PDF) first. Summary of what's here:

- `terraform/` — a small, deliberately flawed Terraform stack for a fictional
  internal app ("paylite"). Part A: review it, find the problems, fix them.
- `incident/` — a mock GuardDuty finding and CloudTrail excerpt. Part C: write
  the incident report.

## Important
- Do NOT run `terraform apply`. No AWS account is needed and nothing should be
  deployed. `terraform init -backend=false`, `fmt`, `validate` and your scanner
  are enough.
- Submit via a Git repository (or zip): your fixed Terraform, your CI pipeline
  config, SECURITY_FINDINGS.md, INCIDENT_REPORT.md, and an updated README.
