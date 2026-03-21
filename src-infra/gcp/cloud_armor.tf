resource "google_compute_security_policy" "waf_policy" {
  name = "todo-waf-policy"

  # Example: block a placeholder IP range (replace with your real blacklist)
  rule {
    action = "deny(403)"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["192.0.2.0/24"] # placeholder blacklist
      }
    }
    description = "Block example IP range"
  }

  # NOTE: Managed/preconfigured WAF rule sets are not supported via this provider version's
  # `versioned_expr` values. To apply Google's preconfigured WAF rule sets, use the GCP Console,
  # the REST API, or a provider version that exposes the PRECONFIGURED_WAF option.
  # See: https://cloud.google.com/armor/docs/managed-protection

  # Example rule matching a malicious User-Agent string. This demonstrates using a CEL expression
  # in Cloud Armor to block requests by header value. Replace the expression with your detection logic.
  rule {
    action   = "deny(403)"
    priority = 1200
    match {
      expr {
        expression = "contains(request.headers['user-agent'], 'BadBot')"
      }
    }
    description = "Block requests with suspicious User-Agent"
  }

  # Default allow rule - explicitly allow all remaining traffic (IPv4). Keep as last/low-priority rule.
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
  }
}

# Note: For rate-limiting (rate-based rules), prefer using a managed rate-based rule via GCP console or
# the REST API; provider support varies by version. A rate-limit template can be added here when the
# provider version supports `rate_limit_options` and `rate_based_key`. See:
# https://cloud.google.com/armor/docs/creating-rate-limiting

# The google provider no longer exposes a separate "google_compute_security_policy_association" resource
# for attaching policies in some versions. Instead, attach the security policy directly on the Backend Service
# using the `security_policy` attribute. The association resource removed to keep compatibility across provider versions.
# If using an older provider that requires the association resource, re-introduce it conditionally.
