# 011 (task): 切り替えた後に、Lokka の環境と鍵を片付ける

起票日: 2026-10-09

## 概要

新しいサイト（010）がしばらく問題なく動いたら、ブログのための GCP の資源と、Lokka が持っていた鍵を片付ける。
Cloud SQL のインスタンス `hoby-db` は**他のサービスと相乗りなので止めない**（002 の背景 2）。

## 着手の条件

010 から 2 週間程度、戻す必要が出なかったとき。

## 手順

1. 010 で取った `lokka_production` の dump を保管先へ移す（AWS の秘密鍵が平文で入るので、置き場所に気をつける）
2. GCP の片付け:
   - Cloud Run のサービス `blog`（`asia-northeast1`）とドメインマッピングを消す
   - Artifact Registry の `blog` リポジトリを消す
   - Cloud Build のトリガー `rmgpgab-blog-asia-northeast1-jiikko-blog--mastnee`（`blog.jiikko.com` ブランチへの push で Docker をビルドして Cloud Run へデプロイする）を消す。2026-11-26 に無効化済み（Hugo 化の commit を push しても Lokka のビルドが走らないように）。戻すときもこのトリガーは要らない（DNS を戻せば、デプロイ済みのリビジョンがそのまま使える）
   - Cloud SQL の DB `lokka_production` を消す
   - DB ユーザー: 004 で作った専用ユーザーがあれば消す。`koji` が他のサービスと共用なら、パスワードを替える（古いブログの env と README に残っているため）
3. AWS の鍵の片付け:
   - `options` の `aws_access_key_id` / `aws_secret_access_key` に対応する IAM のアクセスキーを消す（010 で無効にしていなければ、ここで無効にしてから消す）
   - アップロード用の S3 バケット（`options` の `s3_bucket_name`）は、003 で本文からの参照が無いと分かれば消してよい。参照があれば残す
4. この repo（Lokka の fork）:
   - Lokka の `.ruby-version`・`Gemfile`・`Gemfile.lock` を消したら、Cloudflare Pages の環境変数 `SKIP_DEPENDENCY_INSTALL` を外し、ビルドで Ruby のコンパイル（約 4 分）が消えたことをログで確かめる（005 の 2026-11-26）。`hugo.toml` の `i18nDir` も外す
   - README の「Deploy to Cloud Run」を消し、新しいサイトの repo を指す
   - GitHub で archive する（archive しても読み取りはできるので、書き出しスクリプトは後からでも参照できる）
   - 本文の画像は別の repo `jiikko/cdn` にあるので、この repo を archive しても切れない

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した
- 2026-11-26: Cloud Build のトリガー `blog` を無効化した（`gcloud builds triggers import` で `disabled: true`）。無効化の前の 5 回のビルド（2026-10-09〜10-12）はすべて FAILURE で、本番のリビジョン `blog-00022-qgz` は手で push したイメージ `web:master` のまま
