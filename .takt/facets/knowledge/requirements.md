# 顧客要求事項 (User Requirements)

このプロジェクトでは、以下の要求を最優先事項として実装してください。

## アプリケーション概要

- **種類**: シンプルなTodoアプリ
- **デザイン指針**: Google Todoのようなシンプルで直感的なUI/UX。

## 機能要件

- **用途別バケット（カテゴリ）**: タスクを用途別に分けて管理できる機能（例：仕事、個人、買い物など）。
- **データ永続化**: すべてのタスクデータはRDB (PostgreSQL 17) で永続化すること。

## 技術スタック

- **言語**: Java 17
- **フレームワーク**: Spring Boot 3.x (MVC構成）
- **DB**: Cloud SQL (PostgreSQL 17) — 接続はPrivate IPを利用し、Public IPを無効化すること。接続は閉域網（VPCまたはCloud RunのServerless VPC Access経由）に限定する。
- **インフラ**: Google Cloud (Cloud Run, Load Balancer, Cloud Armor)
