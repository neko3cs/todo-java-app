# Optional automation to enable Cloud Armor managed WAF rule set via gcloud.
# Provider versions may not support managed rule sets directly; this local-exec runs gcloud to attach
# the OWASP managed rule set (example). Requires gcloud installed and authenticated on the machine
# executing terraform apply.

resource "null_resource" "enable_managed_waf" {
  triggers = {
    security_policy = google_compute_security_policy.waf_policy.name
    project = var.project_id
  }

  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
if command -v gcloud >/dev/null 2>&1; then
  echo "Enabling Cloud Armor managed rule set OWASP_3.0 on policy ${google_compute_security_policy.waf_policy.name}"
  gcloud compute security-policies managed-rules update ${google_compute_security_policy.waf_policy.name} \
    --project=${var.project_id} \
    --add-managed-rule-set=OWASP_3.0 || \
    echo "Failed to add managed rule set; run the command manually as described in README."
else
  echo "gcloud not installed; to enable managed WAF run:"
  echo "  gcloud compute security-policies managed-rules update ${google_compute_security_policy.waf_policy.name} --project=${var.project_id} --add-managed-rule-set=OWASP_3.0"
fi
EOT
  }
}
