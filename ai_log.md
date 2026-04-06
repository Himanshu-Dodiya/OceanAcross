# AI Usage Log

**Tools Used:** Grok (xAI), Claude (Anthropic)  
**Tasks Covered:** Task 1–6  
**Approach:** I used AI as a learning companion and documentation assistant — not as a code generator. For infrastructure and pipeline work, I drove the design decisions and debugged failures myself. For documentation-heavy tasks (Task 2, 3, 5, 6), I used AI to help structure professional write-ups after understanding the concepts.

---

## Task 1 — AWS Infrastructure Setup

**Tool:** Grok

### Prompt 1
**Prompt:** Uploaded the full assignment PDF and asked Grok to help me understand each task conceptually before writing any code. Explicitly instructed: "Don't give me direct answer first, I want to understand this as a learning opportunity."

**AI Response:** Gave a high-level breakdown of all 6 tasks, explained why each matters for a UK payroll platform handling sensitive PII, and proposed a step-by-step learning path starting with VPC fundamentals.

**What I used:** The structured learning approach — tackling networking first, then compute, then security layers. This shaped how I organized my Terraform into separate files (networking.tf, compute.tf, security.tf, iam.tf, databases.tf, storage.tf).

**What I rejected:** Grok offered to generate a full text-based architecture diagram immediately — I chose to draw it myself in draw.io after understanding the components.

---

### Prompt 2
**Prompt:** Asked about CIDR block allocation strategy for public and private subnets across two AZs.

**AI Response:** Explained CIDR allocation logic — using 10.0.1.0/24 and 10.0.2.0/24 for public, 10.0.11.0/24 and 10.0.12.0/24 for private. Explained why spacing the ranges gives room for future expansion.

**What I used:** Adopted the CIDR pattern directly in my variables.tf.

---

### Prompt 3
**Prompt:** Wrote my own EC2 + Security Group Terraform code using a `locals` block with 6 hardcoded instances (2 per tenant) and asked Grok to review it.

**AI Response:** Identified multiple issues:
- `for_each` on a list needs `toset()` conversion
- Referencing non-existent security group names (used `company_sg` but only created `tenant_sg`)
- Missing AMI and IAM instance profile
- Task 1 requires one EC2 per tenant type, not two

**What I changed:** Simplified to `for_each = toset(var.tenant_name)` with one EC2 per tenant. Fixed security group references to `aws_security_group.tenant_sg[each.key].id`. Added AMI and instance profile.

---

### Prompt 4
**Prompt:** Asked about securing RDS credentials — didn't want to hardcode username and password in Terraform.

**AI Response:** Presented three approaches: hardcoded (bad), random_password + output (medium), Secrets Manager + random_password (recommended).

**What I used:** Went with Secrets Manager approach — `random_password` for generation, full connection JSON stored in `aws_secretsmanager_secret`.

**What I adapted:** Moved all output blocks to a dedicated `outputs.tf` file instead of keeping them inside `databases.tf` as Grok initially showed.

---

## Task 2 — Multi-Tenancy Architecture

**Tool:** Grok

### Prompt 5
**Prompt:** Asked Grok to explain what Task 2 is really asking — whether it's purely infrastructure or something broader.

**AI Response:** Explained that Task 2 sits at the intersection of Solution Architecture, Security Architecture, and DevOps. The tenant isolation strategy is a system design decision; the infrastructure enforcement is the DevOps piece.

**What I used:** This framing helped me write the document from a DevOps/Platform Engineer perspective — strong on infrastructure boundaries while acknowledging application-level enforcement (JWT, RLS).

---

### Prompt 6
**Prompt:** Asked Grok to help structure a professional write-up for Task 2 covering all three sub-sections (2a, 2b, 2c).

**AI Response:** Generated a document covering: shared DB + tenant_id + RLS as the chosen model, JWT-based tenant propagation, PostgreSQL Row-Level Security policies, S3 prefix-based isolation, and onboarding/offboarding workflows.

**What I used:** Adopted the overall structure and justification for the shared DB model. The RLS policy example and S3 bucket policy JSON were useful references.

**What I adapted:** Reformatted the entire document into my own style (arrow notation with `->` and `=>`, plain .txt file). Tightened the language and removed overly verbose sections.

---

## Task 3 — Security & Access Control

**Tool:** Grok

### Prompt 7
**Prompt:** Asked Grok to help document Task 3, noting that most security controls were already implemented in my Task 1 Terraform code.

**AI Response:** Confirmed ~60-70% was already in code. Generated documentation for all four sub-sections (3a–3d), referencing existing IAM roles, Secrets Manager, encryption, and network isolation.

**What I used:** The S3 bucket policy for denying unencrypted uploads (`StringNotEquals` condition on `s3:x-amz-server-side-encryption`) and the explanation of runtime secret injection via AWS SDK.

**What I adapted:** Converted to my arrow-notation .txt format. Ensured all references pointed to my actual resource names from Task 1 Terraform.

---

## Task 4 — CI/CD Pipeline

**Tool:** Claude

### Prompt 8
**Prompt:** "Help me with building the CI/CD pipeline. Don't give me directly code and procedure — I want to learn this from scratch, like how to think." Shared my initial YAML attempt.

**AI Response:** Identified 4 critical gaps in my pipeline:
1. No multi-team isolation (any push triggers everything)
2. SSM `send-command` fires and forgets — pipeline shows green even if deployment crashed on EC2
3. No dev vs prod environment handling
4. No Dockerfile existed yet

Explained the `wait command-executed` + `get-command-invocation` pattern to fix the SSM problem.

**What I used:** The SSM wait pattern became the core of my deploy job. Also adopted `paths` filters for team isolation — each team's workflow only triggers when their folder changes.

**What I rejected:** Suggested `docker-compose` for deployment — chose plain `docker run` since it's a simple placeholder app.

---

### Prompt 9
**Prompt:** Pasted SSM error output after first pipeline failure: `cd: No such file or directory`, `git: command not found`, `docker: command not found`.

**AI Response:** Diagnosed that EC2 was a blank machine — nothing installed. The error was in EC2 setup, not the pipeline. Gave the bootstrap sequence.

**What I did:** SSH'd into EC2, ran bootstrap myself. Troubleshot Docker group permission issue independently (needed logout/login after `usermod -aG docker`). Pipeline succeeded on next run.

---

### Prompt 10
**Prompt:** Wrote the frontend Dockerfile and workflow myself, shared for review.

**AI Response:** Caught that my "fronend" typo throughout would prevent the `paths` filter from ever matching the actual `frontend/` folder. Also identified missing `docker rm` after `docker stop` in test steps.

**What I changed:** Fixed the typo across all references. Added `docker rm` to all three workflows' test steps.

---

### Prompt 11
**Prompt:** Shared my updated workflow files with `deploy-dev` and `deploy-prod` jobs for environment separation.

**AI Response:** Found a critical bug — `deploy-dev` was running `git pull origin main` instead of pulling the dev branch. The dev environment would always run main branch code, defeating the purpose.

**What I used:** Applied dynamic branch variable in deploy-dev: `BRANCH="${{ github.ref_name }}"`. Kept deploy-prod hardcoded to `git pull origin main`.

---

### Prompt 12
**Prompt:** Shared all three final workflow files (backend, frontend, ai) for a final review pass.

**AI Response:** Found a quoting bug in the `git pull` line in backend.yml and frontend.yml — missing space between `origin` and the branch variable. Also caught frontend.yml missing `dev` in trigger branches.

**What I changed:** Fixed quoting in both files. Added `dev` to frontend trigger.

---

## Task 5 — Monitoring & Incident Readiness

**Tool:** Claude

### Prompt 13
**Prompt:** Asked for help with Task 5. Explained I don't want to spin up RDS (free tier risk) and prefer console-based setup with screenshots as proof.

**AI Response:** Laid out a free-tier-safe plan:
- SNS topic + email subscription (free)
- CloudWatch alarm for EC2 CPU at 80% threshold, 3 consecutive datapoints (free — up to 10 alarms)
- Log groups with 90-day retention
- Stress test command to trigger the alarm for proof
- Generated the task5.txt documentation and one-page incident response runbook

**What I did:** Created all resources via AWS Console myself, ran the stress test, captured screenshots of alarm firing and email notification. Had Claude update task5.txt to reflect what I actually built — EC2 alarm demonstrated live, RDS alarms documented as "same process, not provisioned to avoid charges."

---

## Task 6 — UK Compliance Considerations

**Tool:** Claude

### Prompt 14
**Prompt:** Asked Claude to generate the Task 6 compliance section covering UK GDPR controls, data residency, and right to erasure.

**AI Response:** Generated a document covering AWS-native GDPR controls (encryption, IAM, CloudTrail, Macie, GuardDuty), data residency via eu-west-2 region lock + SCP, and a right to erasure process with deletion across RDS/S3/logs/backups plus audit trail generation.

**What I used:** Took the full document — this required specific UK GDPR knowledge and AWS compliance mapping that I verified were accurate.

**What I adapted:** Reviewed all references to ensure they connect to my actual Task 1 infrastructure (VPC, RDS config, S3 bucket, IAM roles).

---

## Summary

**How I used AI:**
- **Task 1:** Grok for concept learning and code review. Wrote all Terraform myself.
- **Task 4:** Claude as a tutor — learned CI/CD from scratch through guided Q&A. Wrote all workflow files myself, used AI to catch bugs I missed.
- **Tasks 2, 3, 5, 6:** AI helped structure documentation after I understood the concepts. Reformatted everything into my own style.

**Key things I rejected:**
- Docker Compose for a simple placeholder app
- Reusable workflows (_deploy.yml) — understood the pattern but prioritized shipping
- Terraform-based monitoring — chose console approach to avoid RDS charges
- Full code dumps — explicitly asked for teaching-first in both tools

**Debugging I did independently:**
- Read SSM output tab in AWS Console to diagnose EC2 failures
- Fixed Docker group permission issue on EC2
- Resolved port mapping across three services (3000, 8080, 5000)
- Set up GitHub branch protection rules
- Created and confirmed SNS subscription, triggered CloudWatch alarm via stress test