# n8n on GCP (Cloud Run + Supabase) with Terraform

本プロジェクトは、n8n を GCP Cloud Run 上で動作させ、データベースに Supabase Postgres を利用する最小構成の IaC テンプレートです。コンテナイメージは Artifact Registry でホストし、Cloud Build または GitHub Actions で DockerHub の公式イメージをミラーします。

## 構成概要
- Cloud Run: n8n 単一インスタンス（min=1, max=1）
- Secret Manager: `N8N_ENCRYPTION_KEY`, `DB_PASSWORD`, `BASIC_AUTH_PASSWORD`
- Supabase Postgres: TLS 接続（reject unauthorized=false）
- Artifact Registry: n8n イメージの保存先
- Cloud Build / GitHub Actions: 公式イメージのミラー（pull→tag→push）

## 事前準備

### 1. GCP の準備
- GCP プロジェクトと課金有効化
- gcloud / Terraform v1.6+ のインストール
- アカウントの権限: Owner もしくは以下ロール相当
  - Service Usage Admin、Cloud Run Admin、Artifact Registry Admin、Secret Manager Admin、IAM Service Account Admin、Project IAM Admin、Cloud Build Service Account など

### 2. Supabase データベースの準備
1. **Supabase プロジェクトの作成**
   - https://supabase.com にアクセスし、アカウント作成/ログイン
   - 「New project」をクリックして新しいプロジェクトを作成
   - Organization を選択（個人用なら Personal でOK）
   - プロジェクト名を入力（例: `n8n-database`）
   - データベースパスワードを設定（強力なパスワードを推奨）
   - リージョンを選択（推奨: `Northeast Asia (Tokyo)` - GCP と同じリージョン）
   - 「Create new project」をクリック

2. **データベース接続情報の取得**
   - プロジェクト作成完了後、左メニューの「Settings」→「Database」を選択
   - 「Connection info」セクションで以下の情報を確認：
     - **Host**: `aws-xxxxx.ap-northeast-1.aws.supabase.co` 形式
     - **Port**: `5432`
     - **Database**: `postgres`
     - **Username**: `postgres`
     - **Password**: 作成時に設定したパスワード

3. **SSL設定の確認**
   - Supabase は標準で SSL/TLS 接続が有効
   - n8n 設定では `DB_POSTGRESDB_SSL=true` かつ `DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false` で接続

## ディレクトリ
- `envs/prod/` 環境ディレクトリ（Terraform 実行）
- `modules/*` 主要モジュール
- `cloudbuild.yaml` Cloud Build のビルド設定
- `.github/workflows/build-and-push.yml` GitHub Actions ワークフロー

## セットアップ手順（初回）
1. Terraform の初期化
   ```bash
   cd envs/prod
   terraform init
   ```

2. 変数ファイルの準備
   ```bash
   cd envs/prod
   cp terraform.tfvars.example terraform.tfvars
   ```

   `terraform.tfvars` を編集し、以下の値を設定：
   - `project_id`: 作成した GCP プロジェクト ID
   - `db_host`: Supabase から取得したホスト名
   - `db_password_secret_name`: データベースパスワード用のシークレット名（デフォルト: `n8n-db-password`）
   - その他必要に応じて設定を調整

   **設定例**：
   ```hcl
   project_id = "n8n-on-gcp-1234567890"
   db_host = "aws-0-ap-northeast-1.pooler.supabase.com"
   # その他の設定はデフォルトのまま使用可能
   ```

3. Terraform 適用（インフラ初期作成: Artifact Registry, Service Account, Secret 器など）
   ```bash
   terraform apply
   ```

4. Secret のバージョン登録（値の投入）
   Terraform でインフラ作成後、Secret Manager に実際の値を登録：

   **必要な値**：
   - `N8N_ENCRYPTION_KEY`: n8n データ暗号化用キー（強力なランダム文字列）
   - `DB_PASSWORD`: Supabase で設定したデータベースパスワード
   - `BASIC_AUTH_PASSWORD`: n8n UI アクセス用の Basic 認証パスワード

   **暗号化キーの生成**：
   ```bash
   # 強力な暗号化キーを生成
   openssl rand -base64 32
   ```

   **gcloud で Secret に値を登録**：
   ```bash
   # 暗号化キー（生成した値を使用）
   gcloud secrets versions add n8n-encryption-key --data-file=- <<<'4lrUUbfoliPZRmCRSHXyaD64fbwipati3pgMagU9Cs0='

   # データベースパスワード（Supabase で設定したパスワード）
   gcloud secrets versions add n8n-db-password --data-file=- <<<'your-supabase-db-password'

   # Basic認証パスワード（任意の強力なパスワード）
   gcloud secrets versions add n8n-basic-auth-password --data-file=- <<<'your-n8n-ui-password'
   ```

5. イメージのミラー
   **推奨方法（Docker buildx を使用）**：
   ```bash
   # Docker 認証設定
   gcloud auth configure-docker asia-northeast1-docker.pkg.dev

   # n8n イメージを AMD64 プラットフォーム用にミラー
   docker buildx imagetools create --tag asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/n8n/n8n:latest docker.io/n8nio/n8n:latest@sha256:SPECIFIC_DIGEST
   ```

   **代替方法**：
   - Cloud Build を手動実行する場合
     ```bash
     gcloud builds submit --config ../cloudbuild.yaml --substitutions _N8N_TAG=latest,_AR_HOST=asia-northeast1-docker.pkg.dev,_REPOSITORY=n8n ..
     ```
   - GitHub Actions を使う場合
     - リポジトリ Secrets に以下を設定
       - `GCP_PROJECT_ID`: GCP プロジェクトID
       - `GCP_CREDENTIALS`: サービスアカウント鍵 JSON
     - Actions タブから「Build and Push n8n to Artifact Registry」を手動実行し、`n8n_tag` を指定

6. Terraform 再適用（最新イメージタグを `terraform.tfvars` の `image_tag` に設定して適用）
   ```bash
   terraform apply
   ```

7. 動作確認
   - 出力の `service_url` にアクセス
   - **重要**: n8n の初回セットアップ完了後は、Basic Auth は自動的に無効になり、n8n の内部認証システムが使用されます

## 運用上のヒント
- シングルインスタンス運用: `N8N_BINARY_DATA_MODE=filesystem` が前提です
- 固定出口IPが必要になったら: Serverless VPC Connector + Cloud NAT を追加
- 公開制御の強化: カスタムドメイン + Cloud Armor / IAP / Private Ingress など
- ロールバック: Artifact Registry のタグを固定し、`image_tag` を戻して `terraform apply`

## 主要変数（抜粋）
- `project_id`, `region`（例: `asia-northeast1`）
- `repository_id`（例: `n8n`）
- `image_tag`（例: `latest` or `1.63.0`）
- `public`（未認証アクセス許可）
- `db_host`, `db_port`, `db_name`, `db_user`（Supabase 接続）
- `n8n_basic_auth_user`, `n8n_basic_auth_password_secret_name`, `n8n_encryption_key_secret_name`

## トラブルシューティング

### よくある問題と解決方法
1. **データベース接続タイムアウト**
   - Supabase のホスト名が正しい形式 `db.PROJECT_ID.supabase.co` になっているか確認
   - `DB_POSTGRESDB_CONNECTION_TIMEOUT=60000` が設定されているか確認

2. **コンテナ起動の失敗**
   - Artifact Registry にイメージが存在するか確認: `gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/PROJECT_ID/n8n`
   - Cloud Run ログを確認: `gcloud beta run services logs read n8n --region=asia-northeast1 --project=PROJECT_ID`

3. **Docker イメージ push の失敗**
   - マルチアーキテクチャ対応: `docker buildx imagetools create` を使用
   - 特定の digest を指定してプラットフォーム固有のイメージを使用

### デバッグコマンド
```bash
# Cloud Run ログの確認
gcloud beta run services logs read n8n --region=asia-northeast1 --project=PROJECT_ID --limit=50

# Terraform バージョン確認（1.5.0+ 必要）
terraform version

# Secret の存在確認
gcloud secrets list --project=PROJECT_ID
```

## 注意事項
- Secret の値は Terraform 管理に含めません（Secret の器のみ作成）。値は Secret Manager へ手動でバージョン登録します。
- Cloud Run の同時実行数は `var.concurrency` で制御しています。
- 公式イメージの脆弱性対策が必要な場合は、ミドルウェアや CA 証明書などを含めたカスタムイメージ化を検討してください。
- **Terraform 要件**: 当初 v1.6+ としていましたが、v1.5+ で動作することを確認済みです。
