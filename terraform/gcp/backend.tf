# Default to local backend. Update to use GCS backend for remote state in production.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# GCS backend example (commented). To enable, replace the above `terraform { backend "local" { ... } }`
# block with the following and run `terraform init` with proper credentials.
#
# terraform {
#   backend "gcs" {
#     bucket = "<YOUR_GCS_BUCKET>"           # e.g. my-terraform-state-bucket
#     prefix = "<STATE_PREFIX>"              # e.g. terraform/todo-java-app
#     # Optionally set credentials or other backend config here
#   }
# }
#
# You can also pass backend config at init:
# terraform init -backend-config="bucket=my-terraform-state-bucket" -backend-config="prefix=terraform/todo-java-app"
#
# Notes:
# - Create the GCS bucket before running init and grant the Terraform SA storage.objectAdmin on the bucket.
# - Avoid using inline variables inside backend config; provide values via -backend-config or hardcode in the config.
