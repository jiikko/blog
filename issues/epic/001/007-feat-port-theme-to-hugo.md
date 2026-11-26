# 007 (feat): テーマを Hugo へ移植する

起票日: 2026-10-09

## 概要

`public/theme/blog.jiikko.com/` の ERB テーマ（`layout.erb` / `entries.erb` / `entry.erb` / `404.erb`、`style.css`、画像 16 個、`favicon.ico`）を、005 で決めた生成ツール（推奨は Hugo）のテンプレートへ移す。見た目は今と同じにする。

## 移すもの

- レイアウト: ヘッダー（サイト名、`meta_description` / `meta_keywords`、Github と Twitter へのリンク）、フッター、Atom の autodiscovery、favicon
- 一覧: **日付とタイトルのリンクだけ**（`entries.erb`。本文の抜粋は出していない）とページ送り
- 記事ページ: 作成日時（`l(@entry.created_at, format: :long)` と同じ表記）、カテゴリー、タグ（`Entry#tags_to_html` の `<ul class="tags">`）
- 計測:
  - `robots.txt`: 今の本番は 404。置くかを決める
  - Google Analytics: `lokka-google_analytics` プラグインが差し込んでいる。トラッキング ID は DB の `options` にある（003 で名前を確認）
- 本文の中身はそのまま出す。既存の記事は `.html` の content なので、Hugo は Markdown として処理せず、そのまま出す見込み（**未確認**。iframe や data URI が消えないことを 008 の検査で確かめる）。Amazon アフィリエイトの iframe 18 件、YouTube 2 件、data URI の画像 2 件
- コードブロック: kramdown が付ける CodeRay のクラスに対応するスタイルは、今のテーマにも無い（`style.css` に `CodeRay` の定義が無い）。今も色付けされていないので、移植で足すものは無い

## 出さないもの

- 管理画面へのリンク（`logged_in?` の分岐。静的サイトにログインは無い）
- AdSense（`layout.erb` の読み込みの `<script>` 2 箇所と、336x280 の広告枠 `<ins>`）。アクセスが少ないので広告をやめる（2026-11-26 ユーザー決定）。`ads.txt` も置かない
- コメント（今のテーマも表示していない）
- `/search/`（テーマに検索フォームが無い）

## 受け入れ条件

- [ ] トップ・記事ページ・カテゴリー・タグ・年別の各ページを、今の本番と並べて見て差が無い（人の目で見る。スクリーンショットを並べる）
- [ ] GA のタグが全ページに入っている（AdSense のタグはどのページにも無い）

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した。一覧の形、ヘッダーのリンク、AdSense の内訳、`ads.txt` を直した
- 2026-11-18: Hugo の設定・レイアウト・一覧・記事・404・Atom テンプレートを追加し、CSS と画像を `static/` に複製した。DB の記事データ移行と Hugo build による確認は未実施
- 2026-11-18: GitHub Actions に Hugo 0.170.0 の build workflow を追加。`master` への push、`master` 向け PR、手動実行で `dist/` を生成する
- 2026-11-26: 広告をやめると決めた（ユーザー決定）。`layouts/baseof.html` から AdSense の読み込みと広告枠を、`hugo.toml` から `adsenseclient` / `adsenseslot` を外した
- 2026-11-26: 手元の Hugo v0.170.1 で `hugo --gc --minify` が通った。Lokka の `i18n/`（Ruby の翻訳）を Hugo が読んで落ちたので、`hugo.toml` の `i18nDir` を `hugo-i18n` に向けた（Lokka を消す 011 まで）。一時的な記事 1 件でビルドし、記事ページにタイトルと本文が出ることを確かめた。workflow の対象ブランチを `master` から実際の `blog.jiikko.com` に直した
