design/architecture.mmd

# Todo App GCP Infrastructure Design

## 概要
目的: 外部 HTTP(S) トラフィックを Cloud Armor（WAF）付きの Global HTTP(S) Load Balancer で受け、Serverless NEG を経由して閉域網内の Cloud Run（private ingress）にルーティングする。Cloud Run は Serverless VPC Access Connector を用いて VPC 内の Cloud SQL (PostgreSQL 17) に Private IP で接続する。Cloud SQL Admin API は有効化されていることを前提とする。

前提: GCP project_id、region、Terraform state backend 等は未確定（Open Questions を参照）。

## コンポーネント一覧と責務
- External Client: インターネット上のクライアント
- Global HTTP(S) Load Balancer
  - Global Forwarding Rule / Target HTTPS Proxy / URL Map / Backend Service
  - Backend: Serverless NEG (Cloud Run を参照)
  - Cloud Armor セキュリティポリシーを Backend Service にアタッチ
- Cloud Armor: IPブロック、rate-limit、カスタム WAF ルール
- VPC (閉域網): プライベートリソースのネットワーク境界
- Serverless VPC Access Connector: Cloud Run から VPC の Private IP に接続するためのコネクタ
- Cloud Run (private ingress): アプリケーション実行環境。ingress を内部（内部とロードバランサー）もしくは内部のみで制限可能
- Cloud SQL (Postgres 17, Private IP): 永続的なデータストア。Private IP を用いた接続
- 必須 API: run.googleapis.com, sqladmin.googleapis.com, compute.googleapis.com, servicenetworking.googleapis.com, iam.googleapis.com

## 推奨 Terraform リソースマッピング
ファイル分割案:
- terraform/gcp/terraform.tf: required_version, required_providers
- terraform/gcp/providers.tf: google provider（project, region を variables で受ける）
- terraform/gcp/backend.tf: state backend 設定（未確定 → local をデフォルト）
- terraform/gcp/variables.tf: project_id, region, network_name, subnets, connector_name, cloud_run_region, sql_instance_name, sql_tier, service_account_email, domain_name, ssl_certificate_id
- terraform/gcp/apis.tf: google_project_service（必須 API の有効化）
- terraform/gcp/network.tf: VPC, subnet（または既存参照）、google_vpc_access_connector
- terraform/gcp/cloud_sql.tf: google_sql_database_instance (POSTGRES_17), private IP, google_service_networking_connection
- terraform/gcp/cloud_run.tf: google_cloud_run_service（ingress 設定、vpcConnector）、IAM binding (invoker)
- terraform/gcp/serverless_neg.tf: google_compute_region_network_endpoint_group (type=SERVERLESS)
- terraform/gcp/backend_service_lb.tf: google_compute_backend_service, url_map, target_proxy, global_forwarding_rule, ssl_certificate
- terraform/gcp/cloud_armor.tf: google_compute_security_policy, association
- terraform/gcp/iam.tf: service account(s) と role binding（最小権限にする）
- terraform/gcp/outputs.tf: LB IP, Cloud Run internal URL, Cloud SQL private IP, security policy id

## セキュリティ考慮点
- Cloud Run ingress: external からの直接アクセスを禁止し、Load Balancer 経由のみ許可する（ingress = internal, internal-and-cloud-load-balancing 等）
- Cloud SQL への接続制御: Private IP を使用し、必要に応じて IAM と DB ユーザーでの制限を併用
- Cloud Armor: レートリミット、IP ブラックリスト、一般的な OWASP ルールのテンプレート適用
- Service Account 権限: 最小権限の原則で付与（Cloud SQL Client, Cloud Run Invoker は必須）
- ネットワーク: VPC ファイアウォールルールは最小限にとどめる（管理用の踏み台や CI 用の出入口を別に設ける）

## 実装手順（高レベル）
1. variables.tf を定義して project/region 等を受け取る
2. apis.tf で必須 API を有効化
3. network.tf で VPC と Serverless VPC Access Connector を作成（または既存 VPC を参照）
4. cloud_sql.tf で Cloud SQL インスタンス（POSTGRES_17）を Private IP で作成し、service networking を接続
5. cloud_run.tf で Cloud Run サービスをプライベート ingress に設定、vpcConnector を指定
6. serverless_neg.tf で Serverless NEG を作成し Cloud Run を参照
7. backend_service_lb.tf で Backend Service を作成、Serverless NEG をアタッチ、URL Map と Target Proxy、Forwarding Rule を作成
8. cloud_armor.tf で Security Policy を作成し Backend Service にアタッチ
9. iam.tf で必要な Service Account と IAM バインディングを設定
10. outputs.tf で検証に必要な値を出力

## acceptance criteria（受け入れ基準）
- terraform plan/validate が成功すること
- gcloud で以下が確認できること:
  - sqladmin.googleapis.com が有効
  - Cloud SQL インスタンスに PRIVATE IP が割り当てられている
  - Cloud Run サービスが vpcConnector と internal ingress を持つ
  - Serverless NEG と Global Backend Service が存在する
  - Cloud Armor のセキュリティポリシーが Backend Service にアタッチされている
- Load Balancer の公開 IP に対して curl でヘルスチェックが行え、期待応答を得られること（必要に応じて Cloud Armor の deny ルールで 403 を確認）

## Open Questions
- GCP project_id は何か？
- Terraform state backend を GCS にするか？（GCS バケットが利用可能か）
- Cloud Run / Cloud SQL の region はどこか？
- VPC は新規作成か既存利用か？既存の場合は名称/サブネット情報
- SSL 証明書／ドメインは提供済みか？managed cert でよいか？
- Cloud SQL の tier / HA / backup 要件
- Terraform 実行用 Service Account は既存か？作成するか？
- Load Balancer は外部向け global external でよいか？内部 LB を希望するか？

