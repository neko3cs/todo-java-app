# Terraform 設計書 — dev-infra (Load Balancer + WAF, Private Cloud Run, Cloud SQL)

## 概要
この設計書は次を Terraform で実装するための構成案を示す。

1. HTTP(S) Load Balancer + Cloud Armor (WAF)
2. 閉域網（VPC）内で稼働する Cloud Run（internal-only / Serverless NEGs 経由で LB に接続）
3. 閉域網内の Cloud SQL (PostgreSQL 17, Private IP)
4. Cloud SQL Admin API の有効化

図（Mermaid）は別ファイル: docs/dev-infra-architecture.mmd

---

## 前提と要件
- GCP プロジェクトが存在すること
- Terraform v1.5+ と Google Cloud Provider を使用
- 必要な APIs を有効化（下記参照）
- State backend（GCS バケット等）と適切な IAM を用意

### 必須 API
- run.googleapis.com
- compute.googleapis.com
- sqladmin.googleapis.com
- servicenetworking.googleapis.com
- iam.googleapis.com
- cloudresourcemanager.googleapis.com

Terraform での有効化例:

```hcl
resource "google_project_service" "required" {
  for_each = toset([
    "run.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "iam.googleapis.com",
  ])
  project = var.project_id
  service = each.key
}
```

---

## アーキテクチャ（概要）
- Public Internet -> HTTP(S) Load Balancer (Global)
  - URL Map -> Backend Service (Serverless NEG)
  - Cloud Armor Security Policy を Backend Service に適用
- Backend: Serverless Network Endpoint Group (Cloud Run service)
- Cloud Run: ingress = "internal" または最小限のアクセス制御を設定
- Cloud SQL: Private IP を有効にした PostgreSQL 17、VPC の private services access を使用

---

## Terraform リソースマッピング（設計レベル）
1. ネットワーク
  - google_compute_network (VPC)
  - google_compute_subnetwork (サブネット)
  - google_service_networking_connection (private services access)

2. Cloud SQL (Postgres 17)
  - google_sql_database_instance
    - database_version = "POSTGRES_17"
    - settings.ip_configuration.private_network = google_compute_network.main.self_link
    - backups, high availability (optional)

3. Cloud Run (閉域アクセス)
  - google_cloud_run_service
    - ingress = "internal" (サービス単位のインバウンド制御)
    - region, traffic, container image
  - google_cloud_run_service_iam_binding で呼び出し元アクセス制御

4. Serverless NEG（Cloud Run を Backend に使うため）
  - google_compute_region_network_endpoint_group
    - network_endpoint_type = "SERVERLESS"
    - cloud_run { service = google_cloud_run_service.service_name }
  - google_compute_backend_service
    - backend { group = google_compute_region_network_endpoint_group.self_link }
    - security_policy = google_compute_security_policy.waf.self_link

5. HTTP(S) Load Balancer
  - google_compute_url_map
  - google_compute_target_http_proxy / target_https_proxy
  - google_compute_global_forwarding_rule
  - (HTTPS 用に SSL 証明書: google_compute_managed_ssl_certificate または google_compute_ssl_certificate)

6. Cloud Armor
  - google_compute_security_policy
    - rules: rate limiting, OWASP rules, IP blacklist/whitelist

7. API の有効化
  - google_project_service for sqladmin.googleapis.com

---

## 重要設定と考慮点
- Cloud Run を完全に "private-only" にするには ingress 設定だけでなく、IAM 認証（サービスアカウント + IAM 条件）や Serverless NEG 経由の BackendService 設定を正しく行う必要がある。
- Cloud SQL Private IP には `servicenetworking.googleapis.com` を通した private services access が必要。
- Cloud Armor のルールはバックエンドレベルに適用し、必要に応じて Cloud CDN や rate limiting を組み合わせる。
- Terraform 実行順序: APIs 有効化 -> VPC & private services connection -> Cloud SQL (depends on service networking) -> Cloud Run -> Serverless NEG -> Backend Service -> URL Map/Proxy/Forwarding -> Cloud Armor attach

---

## 例: Cloud SQL (簡易スニペット)
```hcl
resource "google_sql_database_instance" "pg" {
  name             = "pg-instance"
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier = "db-f1-micro" # 実運用は適切なマシンタイプを選択
    disk_autoresize  = true
  }

  deletion_protection = true

  # Private IP
  settings {
    ip_configuration {
      private_network = google_compute_network.main.self_link
      ipv4_enabled    = false
    }
  }

  depends_on = [google_service_networking_connection.private_vpc]
}
```

## 例: Cloud Run (簡易スニペット)
```hcl
resource "google_cloud_run_service" "app" {
  name     = "app-service"
  location = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal" # 内部のみ
    }
  }

  template {
    spec {
      containers {
        image = var.container_image
        env {
          name  = "DATABASE_URL"
          value = "postgresql://..."
        }
      }
    }
  }
}
```

## Cloud Armor (簡易スニペット)
```hcl
resource "google_compute_security_policy" "waf" {
  name = "waf-policy"

  rule {
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["1.2.3.0/24"] }
    }
    action = "deny(403)"
  }
}
```

---

## デプロイ順と検証（gcloud コマンド例）
1. Terraform init/plan
2. Terraform apply

検証:
- APIs が有効か: gcloud services list --enabled --project ${PROJECT_ID}
- Cloud SQL: gcloud sql instances describe ${INSTANCE} --project ${PROJECT_ID}
- Cloud Run: gcloud run services describe ${SERVICE} --region ${REGION} --project ${PROJECT_ID}
- Forwarding rules / LB: gcloud compute forwarding-rules list --global --project ${PROJECT_ID}
- Cloud Armor: gcloud compute security-policies describe ${POLICY_NAME} --project ${PROJECT_ID}

例:
```sh
gcloud services list --enabled --project $PROJECT_ID | grep sqladmin.googleapis.com
gcloud sql instances describe pg-instance --project $PROJECT_ID
gcloud run services describe app-service --region $REGION --project $PROJECT_ID
gcloud compute forwarding-rules list --global --project $PROJECT_ID
```

---

## セキュリティと運用
- Secrets (DB パスワード等) は Secret Manager を使用し、Cloud Run にのみアクセスを許可。
- IAM: Cloud Run が Cloud SQL に接続するためのサービスアカウントに roles/cloudsql.client を付与。
- ロギング/モニタリング: Cloud Logging / Cloud Monitoring を有効化し、LB と Cloud Run、Cloud SQL のアラートを設定する。

---

## 次のフェーズ: 実装
- この設計に基づき Terraform モジュールを作成する（network/, sql/, run/, lb/ modules）。
- まず APIs を Terraform で有効化し、VPC と private services connection を作る。
- Cloud SQL を作成後、Cloud Run と Serverless NEG、LB、Cloud Armor を順に作成し検証する。

---

作成者: Terraform / GCP 設計案

