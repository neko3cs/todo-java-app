resource "null_resource" "set_cloud_run_ingress" {
  count = var.enable_post_deploy_ingress ? 1 : 0

  # Trigger when the Cloud Run service name or image changes
  triggers = {
    service = google_cloud_run_service.app.name
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      #!/bin/bash
      set -euo pipefail
      echo "Setting Cloud Run ingress to internal-and-cloud-load-balancing for service ${google_cloud_run_service.app.name}"
      gcloud run services update ${google_cloud_run_service.app.name} \
        --ingress internal-and-cloud-load-balancing \
        --region ${var.cloud_run_region} \
        --project ${var.project_id}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'post_deploy null_resource destroy'"
  }
}

# Note: This uses gcloud from the machine running terraform. Ensure GOOGLE_APPLICATION_CREDENTIALS is set
# and gcloud is authenticated (gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS).
# This is a workaround for provider versions that do not support setting Cloud Run ingress via the Terraform provider.
