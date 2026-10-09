# 007 (feat): テーマを Hugo へ移植する

起票日: 2026-10-09

## 概要

`public/theme/blog.jiikko.com/` の ERB テーマ（`layout.erb` / `entries.erb` / `entry.erb` / `404.erb`、`style.css`、画像 16 個、`favicon.ico`）を、005 で決めた生成ツール（推奨は Hugo）のテンプレートへ移す。見た目は今と同じにする。

## 移すもの

- レイアウト: ヘッダー（サイト名、`meta_description` / `meta_keywords`、Github と Twitter へのリンク）、フッター、Atom の autodiscovery、favicon
- 一覧: **日付とタイトルのリンクだけ**（`entries.erb`。本文の抜粋は出していない）とページ送り
- 記事ページ: 作成日時（`l(@entry.created_at, format: :long)` と同じ表記）、カテゴリー、タグ（`Entry#tags_to_html` の `<ul class="tags">`）
- 広告と計測:
  - AdSense: `layout.erb` に直接書かれている。読み込みの `<script>` が 2 箇所（5 行目と 40 行目）、広告枠の `<ins>` は 1 つ（336x280）
  - `ads.txt` と `robots.txt`: 今の本番はどちらも 404。AdSense のために `ads.txt` を置くのは改善になるので、`static/` に置くかを決める
  - Google Analytics: `lokka-google_analytics` プラグインが差し込んでいる。トラッキング ID は DB の `options` にある（003 で名前を確認）
- 本文の中身はそのまま出す。既存の記事は `.html` の content なので、Hugo は Markdown として処理せず、そのまま出す見込み（**未確認**。iframe や data URI が消えないことを 008 の検査で確かめる）。Amazon アフィリエイトの iframe 18 件、YouTube 2 件、data URI の画像 2 件
- コードブロック: kramdown が付ける CodeRay のクラスに対応するスタイルは、今のテーマにも無い（`style.css` に `CodeRay` の定義が無い）。今も色付けされていないので、移植で足すものは無い

## 出さないもの

- 管理画面へのリンク（`logged_in?` の分岐。静的サイトにログインは無い）
- コメント（今のテーマも表示していない）
- `/search/`（テーマに検索フォームが無い）

## 受け入れ条件

- [ ] トップ・記事ページ・カテゴリー・タグ・年別の各ページを、今の本番と並べて見て差が無い（人の目で見る。スクリーンショットを並べる）
- [ ] AdSense と GA のタグが全ページに入っている

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した。一覧の形、ヘッダーのリンク、AdSense の内訳、`ads.txt` を直した
