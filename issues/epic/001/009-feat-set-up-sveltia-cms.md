# 009 (feat): Git ベースの CMS（Sveltia CMS）を置いて、ブラウザから記事を書けるようにする

起票日: 2026-10-09

## 概要

新しいサイトの `/admin/` に Sveltia CMS を置く。GitHub で認証し、記事を保存すると repo に commit され、Cloudflare Pages が自動でビルドして公開する。
今の Lokka の管理画面（ID/パスワードだけの認証。epic 001 の発端）の代わりになる。

## 対応方針（005 の推奨が通った前提）

- `static/admin/index.html` に Sveltia CMS を読み込み、`static/admin/config.yml` を置く
- `config.yml`:
  - `backend`: `github`、新しい repo、`main` ブランチ
  - `collections`: 記事（`content/posts/`）。項目は 006 の front matter に合わせる（title / date / categories / tags / 本文）
  - 新しい記事の書き方: 本文は Markdown で書く。既存の記事は描画済みの HTML のまま置き、CMS では HTML として編集できる形にする（既存と新規で形式が違うことを `config.yml` で表す方法は要調査）
  - 新しい記事の URL: 005 で決める。slug なら、既存の URL と衝突しないことをビルドで検査する
  - Markdown で書いた記事に iframe などの HTML を混ぜるなら、Hugo の `markup.goldmark.renderer.unsafe` を有効にする（無効のままだと HTML が黙って消える）
  - `media_folder`: 画像を repo に置く（アップロード用の S3 は使わない。003 で、本文が S3 を参照していないかを確かめる）
- 認証: 最初は fine-grained の個人アクセストークン（この repo の contents の書き込みだけ、有効期限付き）。トークンはブラウザに保存される。必要になったら `sveltia-cms-auth` の Worker で GitHub OAuth にする
- 下書き: Sveltia CMS の下書きの扱い（editorial workflow の対応状況）は要調査。無ければ front matter の `draft: true` で代える

## 受け入れ条件

- [ ] ブラウザの `/admin/` から記事を新しく書いて保存すると、repo に commit され、数分で公開サイトに出る
- [ ] repo の書き込み権限が無い GitHub アカウントでは、保存できない

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した
