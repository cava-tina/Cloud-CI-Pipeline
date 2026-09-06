Paylite - Automated, secure infrastructure 

Local Verification Commands : 

1) terraform init -backend=false - initialize provider plugin without connecting to cloud 

2) terraform fmt - used to format the terraform files according to terraform spacing, syntax 

3) terraform fmt -check - used for check code formatting 

4) terraform validate - confirms schema syntax and resource graph validity however does not deploy anything 

Automated CI Pipeline Enforcement - Github Actions 

1) Checkout & History Scope: Utilizes actions/checkout@v4 with fetch-depth: 0 to clone the complete git commit tree.

2) Terraform Syntax Checks : Github Action runner utilize terraform terraform init -backend=false, terraform fmt, terraform fmt -check and terraform validate ensuring terraform is syntactically valid pre merge 

3) Automated security gating : Executes Bridgecrew's Checkov framework across the Terraform directory with soft_fail: false, ensuring any structural cloud misconfigurations immediately break the build

4) Secret detection gate : Gitleaks uses if: always() to ensure secret scanning runs even if preceding checks fail. It downloads Gitleaks v8.24.3, scans historical commits (--redact), outputs a SARIF compliance report (/tmp/gitleaks-results.sarif), and throws exit code 2 on detection to block vulnerable code from merging

Checkov Findings Resolution : 

Remediated Findings (Applied fixes in Main.tf file)

1) CKV_AWS_293 - RDS Deletion Protection Disabled 

a) Status : Fixed 

b) Action : Added deletion_protection = true to aws_db_instance.paylite_db

c) Rationale: Enabling this feature ensures critical security patches or bug fixes are applied automatically thus preventing potential zero day attacks 

2) CKV_AWS_23 - Security Group Rule for Paylite missing descriptions 

a) Status : Fixed 

b) Action : Added description = "paylite app access restricted to corporate VPN and internal application subnets" 

c) Rationale : Enforces more transparent network security audits and one of security group best practice 

Accepted Risks & Architectural Tradeoffs 

1) CKV_AWS_157 - RDS Multi AZ Deployment

a) Status : Accepted Risk 

b) Rationale : Setting up Multi AZ Deployments will increase the database infrastructure cost due to additional storage. Since paylite is a lightweight internal non production financial reconciliation tool used by internal staff, single AZ deployment is acceptable. This tradeoff is reassured via automated snapshots or backup vaults such as AWS Backup Vault

2) CKV_AWS_161 - IAM Database Authentication 

a) Status : Accepted Risk 

b) Rationale : IAM database authentication requires app level support for generating short lived authentication tokens, since currently using credential based authentication which is applied using environment variables injected at runtime instead of hardcoding plaintext credentials in the code. The use of IAM DB authentication is undeniably best practice, but may become a blocker due to app compatibility issues unless app undergoes necessary changes to support this method

3) CKV_AWS_118 & CKV_AWS_353 - Enhanced Monitoring & Performance Insights


a) Status : Accepted Risk 

b) Rationale : Metrics on the OS level and detailed query profiling agents would bring about additional logging overhead coupled with extra cost since paylite is a small application cloudwatch should be sufficient

4) CKV_AWS_129 - RDS CloudWatch Log Exports

a) Status : Accepted Risk 

b) Rationale : This feature allows logs from the RDS database such as error logs or slow query logs to be exported to Cloud Watch for centralized logs. Since the app is for internal use, the database current storage should be sufficient 

5) CKV_AWS_382 - Open Outbound Egress 0.0.0.0/0 on Port -1

a) Status : Accepted Risk 

b) Rationale : Paylite would require outbound internet connection to perform security patches downloads or communicating with external banking APIS and is acceptable since is not public facing production grade application and is within private subnets and restricted access via security groups, IAM permissions and SCPs 

6) CKV_AWS_273 & CKV_AWS_40 - IAM User vs. AWS SSO & Direct Policy Attachments

a) Status : Accepted risk 

b) Rationale: Since the app is lighweight and internal use, IAM user is currently acceptable. However in future security upgrades it is best to use IAM role coupled with OIDC which eliminates access keys 

Additional Pipeline and workflow enhancements 

1) Native Sarif Security Dashboard Integration 

Configure GithubActions to upload the Gitleaks Sarif report to GitHub Security tab, better visibility into vulnerabilities 

2) Migrate from IAM Users to OIDC 

Replace static long lived IAM access keys used in CI pipeline with IAM role coupled with OIDC eliminating need to manage access keys manually 

3) Shift left local pre-commit hooks 

Add a .pre-commit-config.yaml bundle containing Gitleaks and tflint so developers catch formatting errors and hardcoded secrets on their local machines before pushing code to production branches in Github repo 

4) Module Versioning and private registry publishing 

Refactoring the monolith main.tf file into clean, reusable child modules covering database, networking, IAM which is then published to an internal private Terraform registry enforcing security best practices 

AI Guided Sections

1) Verified my doubts on the vulnerabilities found in the main.tf, where vulnerabilities were found and confirmed with AI 

2) Provided a structure for documentation based on my target scope and focus 

3) Provided CI pipeline skeleton, syntax and provided solution for Gitleaks wrapper issue 


Tasks AI failed to assist 

1) Architectural trade offs, where after evaluation I proceeded to fix the necessary vulnerabilities/ errors found in checkov instead of fixing every single error. There were certain errors that if given more time I would have fixed them related to identity security. 

2) Specific details on documentation such as the contents on justifications and suggestions as solutions provided by AI may not be relevant or not detailed enough 


