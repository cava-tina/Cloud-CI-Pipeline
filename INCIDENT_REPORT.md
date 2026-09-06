INCIDENT POST-MORTEM & FORENSIC ANALYSIS

Incident ID: INC-2026-0726-PAYLITE

Date of Incident: July 26, 2026

Severity: Critical

Status : Resolved 

Executive Summary 

On July 26, 2026 an external threat actor sucessfully compromised the IAM user "svc-paylite-deploy" within the paylite app AWS account environment. The breach orginated from plaintext hardcoded AWS access keys and secret access keys credentials in the repository's Terraform configuration file, main.tf. The attacker then used these keys to perform account enumeration, created persistent IAM acess keys followed by spinning ip unatorized g4dn.xlarge EC2 compute instances in the region us-east-2 for illicit cryptocurrency mining. 

Automated threat and security telemetry via AWS Guard Duty detected the crypto mining incident within 45 minutes of deployment. Containment actions were immediately executed via revocation of unauthorised credentials, isolating computing instances, remdiating through least privilige IAC hardening. 

Blast Radius Assessment 

Financial Impact 

1) Computing costs : Provisioning of 4 g4dn.xlarge GPU instances in us-east-2 introduced a burn rate of about 2 dollars per hour. Since the incident was remediated quickly it resulted in minor billing costs and minimal resource wastage 

2) API & Data Transfer : High frequency network traffic anf external api connections result in addtional costs 

Data Exposure 

1) S3 enumeration due to the attacker being able to perofrm ListBuckets action and inspected storage layout design across account 

2) Confidentiality Risk : The implmentation of legacy ACL based bucket configuration lacked rules which blocked Public Access resulting in a public-read ACL, where sensitive internal financial reconcillation records stored within bucket face severe risk of data exposure and exfiltration 

Infrastructure Integrity 

1) Regional Hijacking where attacker utlized an unmonitored region for mining by deploying a wide open security group allowing unrestricted inbound and outbound traffic and spun expensive GPUs 

2) Lateral expansion where the attacker attempted to scale the operations by provisioning another 8 g4dn.12xlarge GPU instances in ap-southeast-1 region however was mitigated with strict SCP rules. 

Identity and Acess Control Compromise 

1) Wildcard Privilege Scope where the IAM user svc-paylite-deploy held admin level policy allowing unchecked unauthorised account wide actions 

2) Attacker managed to persist in account by creating a new set of IAM access keys which allowed them to continue mining even if the main set of keys was discovered 

Chronology of Attack 

17:41:22 UTC — Initial Access & Reconnaissance

CloudTrail findings:

GetCallerIdentity and the ListBuckets were called from a spcific ip address, 185.220.101.47 via the compormised IAM user svc-paylite-deploy via the access key AKIA5EXAMPLE9DEPLOY1

Context : 

The attacker harvested the hardcoded plaintext IAM user credentials and tested it validity via AWS CLI using aws configure where access key were entered and inititated sts get caller identity which lists out the User Id and account details. The attacker also managed to list the buckets in the account due to overly permissive IAM user svc-paylite-deploy policy where they were able to perform any action on any resources 

17:44:51 UTC — Persistence Establishment

CloudTrail findings: 

Attacker using the compromised IAM user credentials managed to perform action CreateAccessKey which resulted in the creation of AKIA5EXAMPLE2PERSIST. 

Context : 

In event the original compromised keys were discovered and revoked , the attacker still could perform other actions using the newly generated access key. 

17:51:38 to 17:58:03 UTC — Infrastructure Hijacking & Cryptomining Deployment

CloudTrail Findings : 

Throughout this time period, the attacker performed actions such as CreateSecurityGroup, AuthorizeSecurityGroupIngress and RunInstances in the region us-east-2. 

Context: 

The attacker chose to operate in an unauthorized region, us-east-2 where a wide open security group, sg-0feedfacecafe0001 which exposed all ports and allowed all incoming traffic followed by launching 4 high performance GPU instances with the size g4dn.xlarge with instanceID i-0badc0ffee1234567 ideal for crypto mining. 

18:03 UTC — Blocked Lateral Expansion

CloudTrail Findings: 

Attacker attempted to replicate and scale his operations in the regio ap-southeast-1 by performing RunInstances command on GPU Instances with size g4dn.12xlarge" and up to 8 instances. 

Context: 

The efforts however were futile as the Service Control Policy successfully blocked the unauthorised spinning of GPU Instances. 

18:47:12 UTC — Threat Detection Triggered

GuardDuty Findings: 

GuardDuty Log Id f2c1e9a7b8d34e5f9a0c1d2e3f4a5b6c found the instance i-0badc0ffee1234567 quering external unauthorised domains linked to crpto mining. 

Context: 

GuardDuty has flagged over 214 DNS lookup request originating from EC2 instance i-0badc0ffee1234567 which targets a known crypto mining pool domain pool.minexmr.example.com. GuardDuty required time to flag the incident due to the need to process DNS queries as a single DNS lookup might not be worth flagging and might generate excessive noise. Instead, it detects for persistent actions such as the numerous lookups made by the EC2 used for mining which is correlated with the threat feed to determine the destination and its purpose. 

Root Cause Analysis 

The crypto mining incident was due to three compounding security flaws present in the main.tf file code architecture which are: 

1) Hardcoded secrets : Plaintext, hardcoded access key and scret access keys were defined in the terraform provider block. When the codes are pushed to the Github repo, the hardocded secrets will remain in the Git Commit history unless explicitly erased. 

2) Overly Permissive IAM User Policy: The IAM User svc-paylite-deploy was granted with permissions such as Action : "*" and Resource : "*" directly violating the least privilige principle by allowing the user to perform any action without guardrails which allowed the unauthorized user key creation and EC2 provisioning 

3) Regional oversight: The lack of SCP guardrails restricting regions active in the account allowed the attacker to easily spin up resources in the region us-east-2

Containment and Remediation 

1) Revoke and deactivate all compromised IAM access keys 

Action : Deleting AKIA5EXAMPLE9DEPLOY1 and AKIA5EXAMPLE2PERSIST

Relevance : Severing IAM credentials to ensure attacker can no longer have access to APIs or AWS account resources and halt any firther unathorized actions 

2) Isolating compromised compute instances on network level 

Action : Attaching a temporary strict Security Group to instance i-0badc0ffee1234567 blocking all inbound or outbound traffic, due to their stateful property and preventing blockage of other legitimate network traffic 

Relevance: Strict security groups can immediately stop the instance from querying the external mining pool thus halting its activity

3) Capturing EBS Forensic Snapshots 

Action: Taking point in time snapshot of the root volume of i-0badc0ffee1234567 prior to deletion 

Relevance: This action preserves the processes running in volatile memory and disk based eveidence for offline research while eliminating the online threat 

4) Terminating unathorised compute instances 

Action : Terminate all the rogue g4dn.xlarge instances in the us-east-2 region 

Relevance: Done after preserving evidence, which eliminates ongoing financial burn and shadow infra 

5) Purging git repo history and deploying hardened IAC 

Action : Purge the Git Commit History to eliminate any sources of hardcoded secrets and deploy the hardened main.tf file 

Relevance: This ensures the environment is updated with the necessary security best practices that prevents future similar incidents and prevents blocking legitimate users

Prevention Improvement 

Mandatory pre-commit and CI CD Automated Gating 

Shifting left bakes security directly into code eliminates vulnerability root causes before the code even merges into the main branch. This is implemented via : 

1) Local prevention thorugh pre-commit hooks where developers install local hooks that scans staged files. In event a secret is detected in main.tf or any tf files in the stack, the git commit command is blocked preventing the keys from ever committed in the local history 

2) Automated Gating in CI Pipeline ensures even if local hooks are bypassed, the soft_fail: false setting which is a strict security setting will automatically fails the CI pipeline deployment in event a secret, misconfigurations are detected 


 