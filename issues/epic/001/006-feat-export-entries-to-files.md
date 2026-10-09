# 006 (feat): 記事を DB から Hugo 用のファイルへ書き出すスクリプト

起票日: 2026-10-09

## 概要

本番 DB の公開記事（と、あれば Page）を、Hugo の content ファイルとして 1 記事 1 ファイルで書き出す。
本文は**今のアプリが描画した HTML**で持つ。Textile・kramdown・redcarpet・HTML が記事ごとに混ざっているので（`Markup.engine_list`）、Markdown へ変換すると見た目が崩れる危険があるため。

## 詳細

書き出しは 1 回だけ（乗り換えた後は CMS で書く）。今のアプリのモデルをそのまま使うのが一番確実なので、この repo に rake タスクを置いて、本番 DB の dump を入れた手元の MySQL に対して走らせる。

- 出力: `content/posts/<fuzzy_slug>.html`（`fuzzy_slug` は slug が空なら id。`Entry#fuzzy_slug`）
- front matter に入れるもの:
  - `title`
  - `date`（created_at）と `lastmod`（updated_at）
  - `url`（`Entry#link` と同じ `/<fuzzy_slug>`）
  - `lokka_id`
  - `categories`（id とタイトル。URL が `/category/<id>/` なので id を持つ）
  - `tags`
  - `markup`（元の種別。記録用）
  - `feed_id`: 今の Atom の `<id>` の文字列そのもの（`tag:https://blog.jiikko.com:443,` + `created_at.to_s`。`public/lokka/index.builder`）。日時を補正しても、こちらは変えない（008）
- 本文: `Entry#long_body`（`Markup.use_engine(markup, raw_body)` の結果）。`<!-- more -->` は残す
  - 今の一覧ページは本文を出していない（`entries.erb` は日付とタイトルだけ）
  - `<!-- more -->` で切った `short_body` を使うのは、feed と sitemap だけ（`apply_continue_reading`）。feed の本文を今と同じにするなら要る（008）
- 出さないもの: 下書き（003 の結果で決める）、コメント、ユーザー

## 先に決める・確かめること

- 003 の結果: Page の有無、下書きの扱い、マークアップの内訳、日時のずれ
- **日時**: 本番の feed で、`published`（created_at）が同じ日の `updated`（updated_at）より後の記事がある（id 210: published `2026-04-10T19:49:19+00:00`、updated `2026-04-10T10:31:41+00:00`）。created_at だけが JST で保存され、`+00:00` を付けて出ている疑いがある。003 の SQL で確かめ、書き出しで正しいタイムゾーンを付ける
  - Atom の `<id>` は created_at の文字列を含む（008）ので、補正しても `<id>` 用には元の文字列を `feed_id` に持つ
- 手元で動かす環境: `bin/dev-container` はビルドで止まっている（`container` のビルダーが Rosetta 前提の設定。Rosetta は入れない方針なので `container system property set build.rosetta false` で回避する）。MySQL 8.0 のコンテナも 1 つ要る

## 受け入れ条件

- [ ] 書き出した件数が、003 で数えた公開記事の件数（クロールでは 173 件）と一致する
- [ ] 全記事について、今の本番の記事ページの本文 HTML と、書き出した本文が一致する（空白の差は除く）。機械で突き合わせる
- [ ] slug を持つ記事（`/resque`）が slug の URL で出る

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した。一覧が本文を出していないこと、`feed_id` を足した
- 2026-10-09: 方針を変えた（ユーザーの提案）。Markdown（kramdown / redcarpet）の記事は `raw_body` を `content/posts/<fuzzy_slug>.md` に出し、Hugo で描画した結果を本番の本文と比べて、ずれた記事だけ `long_body` の `.html` にする。Textile と HTML の記事は今までどおり `long_body` の `.html`。件数の内訳は 003 で取る。上の「本文」「受け入れ条件」は、003 の結果を見てから書き直す
