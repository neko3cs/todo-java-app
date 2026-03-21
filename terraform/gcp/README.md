# Terraform GCP - Todo App

This directory contains Terraform configuration to provision a Google Cloud architecture consisting of:
- Global HTTP(S) Load Balancer (external) -> Serverless NEG -> Cloud Run (private ingress)
- Cloud Armor security policy attached to Backend Service
- VPC + Serverless VPC Access connector
- Cloud SQL (Postgres 17) with Private IP

Prerequisites
- Install Terraform (>= 1.0)
- Set Google credentials: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
- Ensure gcloud is installed if you plan to use post-deploy automation (post_deploy.tf uses gcloud)
- Enable IAM rights for the account running Terraform (owner or appropriate roles)

Quickstart
1. Edit terraform/gcp/variables.tf or use a vars file with required values (project_id is required).
2. Initialize: terraform init
3. Validate: terraform validate
4. Plan: terraform plan -var-file=vars.tfvars
5. Apply: terraform apply -auto-approve -var-file=vars.tfvars

Remote state (GCS backend)
- A sample GCS backend configuration is included in terraform/gcp/backend.tf as a commented snippet.
- To migrate to a GCS backend:
  1. Create a GCS bucket (e.g. my-terraform-state-bucket) and enable uniform bucket-level access.
  2. Grant the Terraform service account storage.objectAdmin (roles/storage.objectAdmin) on the bucket.
  3. Replace the local backend block in backend.tf with the GCS backend snippet, or run:
     terraform init -backend-config="bucket=my-terraform-state-bucket" -backend-config="prefix=terraform/todo-java-app"
  4. Verify remote state initialized successfully.

Notes & Open Questions
- Backend: currently configured as a local backend by default (backend.tf). For production, use a GCS backend and update backend.tf accordingly.
- SSL: For simplicity this scaffold uses HTTP forwarding. To enable HTTPS with managed certificates, update backend_service_lb.tf and provide DNS.
- Some resources (Cloud SQL Private IP) require service networking ranges; this config creates a reserved peering range. Adjust as needed.
- Replace placeholder images, domains and service account emails before applying in production.

Post-apply steps (gcloud required)
- This configuration includes terraform/gcp/post_apply.tf which runs gcloud commands locally during terraform apply to:
  * Set Cloud Run ingress to internal-and-cloud-load-balancing (provider may not support top-level ingress attribute).
  * Print guidance and example commands to enable Cloud Armor managed rule sets and rate-limiting.

Optional automation: Cloud Armor managed WAF
- terraform/gcp/cloud_armor_managed.tf contains a null_resource that attempts to enable Google's OWASP managed rule set (OWASP_3.0) using gcloud.
- This is optional and requires gcloud installed, authenticated, and the executing identity to have permission to modify security policies.

Before running terraform apply:
1. Ensure gcloud is installed and authenticated with permissions to modify Cloud Run and Cloud Armor:
   - gcloud auth login
   - or gcloud auth activate-service-account --key-file=/path/to/key.json
2. Replace variables (project_id, service_account_email, image, domain) with production values.
3. Run terraform apply -var 'project_id=REAL_PROJECT' -var-file=vars.tfvars

If post_apply or managed-WAF commands fail, follow the printed guidance to run the gcloud commands manually. See Cloud Armor docs:
https://cloud.google.com/armor/docs/managed-protection
