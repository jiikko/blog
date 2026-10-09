# 002 (design): 静的サイトへの乗り換えの計画と調査（epic 001 の本文）

起票日: 2026-10-09

> epic [001](001-task-migrate-to-git-managed-static-site.md) の本文。2026-10-09 に 001 から移した（glogx の issues viewer では、epic の親行の `Enter` が子リストの開閉になるので、本文は子 issue に置く）。
> 状態: **検討中**（乗り換えるかどうか自体がまだ決まっていない。2026-10-09 時点で、ユーザーは「ちょっと考え中」）。
> 決まるまでは、残りの子 issue を起票せず、下の「決めること」を埋めていく。

## 概要

今の Lokka（Ruby 2.6 / Sinatra 1.4 / DataMapper）を Cloud Run + Cloud SQL (MySQL 8.0) で動かす構成をやめる。
記事を repo の中のファイル（Markdown か HTML）として持ち、静的サイトとして配信する。
管理画面は Git ベースの CMS にして、ブラウザから GitHub アカウントで認証し、編集を保存すると repo に commit が積まれる形にする。

## 背景（なぜ乗り換えを考えているか）

1. **管理画面の認証を強化したい**（話の発端）
   - 今の `/admin` は Lokka 組み込みの ID/パスワードだけ（`lib/lokka/app/admin.rb` の `post '/admin/login'`）
   - 検討した代替案と見送った理由:
     - 外部 LB + IAP / Cloud Armor: LB の固定費が高い
     - Cloudflare Access: DNS の移管と、`run.app` を直接叩かれる経路の対策が面倒
     - アプリへの TOTP 実装: その後の upgrade の話で保留
   - 静的サイトにすれば `/admin` が無くなり、編集の認証は GitHub のもの（2 段階認証・パスキー）になる
2. **共有の DB にぶら下がっている攻撃面を減らしたい**
   - Cloud SQL のインスタンス（`hoby-db`）は**他のサービスと相乗りしている**ので、乗り換えてもインスタンスは消せず、固定費は減らない（ユーザー談 2026-10-09）
   - そのぶん、セキュリティの理由が強くなる。ブログは EOL の Ruby 2.6 / DataMapper で動いていて、その共有インスタンスへ接続している（README の `DATABASE_URL` は `mysql://koji:…@…/lokka_production`）
   - `koji` ユーザーが他のサービスの DB にも権限を持っていれば、ブログが破られたときに他のサービスのデータまで届く。**権限の範囲は未確認**（`SHOW GRANTS FOR 'koji'@'%';` で確かめる）
   - 静的サイトにすれば、ブログから DB への接続そのものが無くなる
   - 参考: Cloud SQL には scale to zero のサーバーレスの形態が無い（2026-10 時点で該当する発表は見つからず）
3. **upgrade が重い**
   - upstream (lokka/lokka `main`) は DataMapper → ActiveRecord・Ruby 3.2 以上・Sinatra 4 へ作り直されている
   - Ruby だけを上げる経路は upstream に無い（AR 化の commit `8deaf37` の上に Ruby 更新が積まれている）
   - 取り込むと次の作業が要る（2026-10-09 の確認）:
     - mysql2 対応
     - DB の移行。`db:migrate` は既存テーブルで失敗し、移行ツールは挿入の失敗を握り潰す
     - テーマのページ送りの書き直し（`@posts.pager.to_html` が `''` を返す）
     - `POST /api/v1/token` への対処（管理画面のログインとは別の経路で、パスワードから API トークンを発行する。管理画面に入れる 2 段階認証が効かない）
     - Akismet の削除でコメントの `status` を投稿者が指定できるようになる件への対処
   - 静的サイトにすれば、この追従作業そのものが無くなる

## 費用の見積もり（実測ではない）

記憶にある料金表に基づく見積もりで、2026 年の正確な料金と実際の PV は未確認。

| 構成 | 固定費 | 従量（10 リクエスト・500KB/view の前提） |
|---|---|---|
| 今（Cloud Run + Cloud SQL） | Cloud SQL が月 $10 前後。ただし他のサービスと相乗りなので、乗り換えても減らない（画像の S3 バケットの費用も別で、どちらの構成でも残る） | 外向きの転送量が主で約 $0.00007/view。個人ブログの規模ならほぼ無料枠内 |
| Cloudflare Pages | $0 | $0 |
| S3 + CloudFront | Route 53 の $0.50/月（既に払っている） | CloudFront の常時無料枠（月 1TB・1,000 万リクエスト）内なら $0 |

**trigger**: 乗り換えを決めるときに、GCP の請求のサービス別内訳（Cloud SQL / Cloud Run / Networking）で実額を確かめる。

## 現状の事実（2026-10-09 に確認。反証レビュー 2 本の指摘を本番への curl とコードで再確認済み）

- **記事の URL**: `/<id>`（例: `/210`）。トップ・記事ページ・Atom のどれにもカスタムパーマリンクの slug は見えない
  - 記事を出すルートは汎用の `get %r{^/([_/0-9a-zA-Z-]+)$}`（`lib/lokka/app/entries.rb`）で、Post と Page の両方を id か slug で引く
  - **Page（固定ページ）があるかは未確認**（DB を見ていない）
- **公開記事数: 173 件**（反証レビューがページ送りの各ページのリンクを数えた。1〜17 ページが 10 件ずつ、18 ページが 3 件）
  - id は飛び番（`/205` は 404、`/210` は 200）。下書きか削除済みと思われる
- **ページ送り**: `?page=N`（クエリ文字列）。トップ以外のカテゴリー・タグ・アーカイブ・検索の一覧も同じ形
  - 範囲外の `?page=19` も 200 で、記事 0 件のページを返す
- **月別アーカイブ `/YYYY/MM/` は本番で 500**（`/2025/01/` と `/2024/12/` で確認）。年別 `/YYYY/` は 200
  - 維持すべき URL ではなく、今壊れている。原因は未調査
- **feed と sitemap は 1 ページ分だけ**
  - `/index.atom` と `/sitemap.xml` も `page(params[:page], per_page: @site.per_page)` で区切られていて、10 件しか出ない
  - sitemap の `<url>` 11 件は、トップ + 10 記事
  - 出力される URL には `https://blog.jiikko.com:443/210` のように `:443` が付く
  - Atom の `<id>` は `tag:<host>,<created_at>`（`public/lokka/index.builder`）
- **アップロードした画像は外部の S3 バケットにある**
  - `POST /admin/attachments` → `handle_file_upload`（`lib/lokka/helpers/helpers.rb`）が、`Option.s3_bucket_name` のバケットへ `<md5>.<ext>` で上げる
  - 記事には `Option.s3_domain_name`（無ければバケットの URL）の絶対 URL で埋め込まれる
  - バケット名・ドメイン・AWS の鍵は DB の `options` テーブルにあり、**秘密鍵も平文**
- **テーマ `public/theme/blog.jiikko.com`** は ERB
  - コメントを表示していない
  - AdSense のタグが `layout.erb` に直接書かれている（2 箇所）
  - 本番の `robots.txt` と `ads.txt` は 404
- **表示に関わるプラグイン**: `lokka-google_analytics`。トラッキング ID は DB の `options` にある
- **記事のマークアップ**: 記事ごとに html / kramdown / redcloth（Textile）/ redcarpet から選ぶ（`lib/lokka/models/markup.rb`）
  - kramdown のコードには CodeRay の CSS クラスが付く
  - 記事ごとの内訳は未確認
- **DB にある記事以外のデータ**: Page、下書き、snippet、カスタムフィールド（`field_names` / `fields`）、カテゴリーの親子関係、タグ、コメント、`updated_at`
- **タグ**: 記事やトップにタグのリンクは見当たらない。`/tags/a/` は 404。使っていない可能性がある。カテゴリーは `/category/4/` が 200
- **その他**: DNS は Route 53。`blog.jiikko.com` は Cloud Run のドメインマッピング（Google の IP）を向いている。本番 DB は Cloud SQL の MySQL 8.0

## 決めること

- [ ] 乗り換えるかどうか
- [ ] 配信先: Cloudflare Pages / S3 + CloudFront / GitHub Pages
- [ ] 静的サイトの生成ツール: Hugo / Astro / Jekyll など
- [ ] CMS:
  - Sveltia CMS（`/admin/` に設置。GitHub 認証の中継に Cloudflare Worker を 1 つ置く）
  - Pages CMS（ホスト型。インフラ不要だが、管理画面は Pages CMS 側のドメイン）
  - 自作（GitHub App + Worker + GitHub API）。既存のもので足りない部分が具体的に出てから検討する
- [ ] 記事の持ち方:
  - 本文を Markdown に変換する
  - 今のアプリで描画済みの HTML として書き出す（Textile などが混在していても見た目が崩れない）
- [ ] ページ送りの扱い: 静的配信ではクエリ文字列 `?page=N` を区別できない。`/page/N/` に変えてリダイレクトするか、捨てるか（トップ以外の一覧も同じ）
- [ ] 画像の S3 バケット: 残して URL をそのまま使うか、repo か配信先へ移して URL を書き換えるか
- [ ] `/search/` とコメント投稿: 静的サイトには対応するものが無い。捨てるか、外部サービスで代替するか

## 移行の手順（決まったら子 issue に切る）

1. **本番 DB の中身を数える**: Page の有無、下書き、記事ごとのマークアップの内訳、snippet、カスタムフィールド、カテゴリーの親子関係、タグの使用状況、`options` の中身（S3 バケット・GA の ID）
2. **書き出す**: 公開記事（下書きは除くか、未公開のまま持つ）、Page、カテゴリー、タグ、`created_at` / `updated_at`
3. **テーマを移植する**: CodeRay の CSS、AdSense、GA を含める
4. **URL を維持する**:
   - 記事 `/<id>` と、Page や slug で引かれていた URL
   - `/index.atom`、`/category/…`、`/YYYY/`（`/YYYY/MM/` は今 500 なので、作るなら新設として扱う）
   - 変わるものはリダイレクトする（Cloudflare Pages の `_redirects` は静的なルールが 2,000 件まで。今の規模なら足りる見込み）
   - 末尾のスラッシュの有無は今と同じにし、リダイレクトのループが無いか確かめる
5. **feed と sitemap を作り直す**:
   - sitemap は全記事を載せる（今は 10 件だけ）
   - Atom の `<id>` は今の `tag:<host>,<created_at>` の形を保つ。保たないと feed リーダーで全記事が新着に見える
   - URL の `:443` は付けない形に変わる
6. **CMS を設置する**
7. **切り替える**:
   - 編集を止める
   - DNS の TTL を下げておく
   - 配信先へ DNS を切り替える
   - Search Console に sitemap を出し直す
   - 戻すときは DNS を Cloud Run へ向け直す
8. **後始末**: しばらく並行して置き、問題がなければブログの Cloud Run サービスと Artifact Registry を止める
   - Cloud SQL のインスタンスは他のサービスと相乗りなので止めない。消すのはブログの DB（`lokka_production`）だけにする
   - ブログ専用の DB ユーザーがあれば、それも消す。`koji` が他のサービスと共用なら、パスワードをローテーションする
   - 消す前に `lokka_production` の `mysqldump` を保管する
   - dump には `options` にある AWS の秘密鍵が平文で入る。dump の置き場所に気をつけ、鍵はローテーションする

## 関連ファイル

- `lib/lokka/app/entries.rb` — 公開ルート（維持すべき URL の一次情報）
- `lib/lokka/app/admin.rb` — 今の管理画面とログイン
- `lib/lokka/helpers/helpers.rb` の `handle_file_upload` — 画像を S3 へ上げる処理
- `public/lokka/index.builder` / `public/lokka/sitemap.builder` — 今の feed と sitemap
- `public/theme/blog.jiikko.com/` — 移植するテーマ
- `README.md` の「Deploy to Cloud Run」 — 今のデプロイ手順（乗り換えたら書き換える）
- `bin/dev-container` — 今のアプリを手元で動かすスクリプト（記事の書き出しに使える）

## 進捗

- 2026-10-09: 001 として起票。乗り換えるかは検討中
- 2026-10-09: 反証レビューを 2 本（事実の照合 / 計画の抜け。sonnet の読み取り専用サブエージェント）に通した
  - 本番への curl とコードで再現した指摘をすべて反映した: 月別アーカイブの 500、feed と sitemap が 1 ページ分だけ・`:443` 付き、S3 の画像、AdSense と GA、記事数 173、Page と下書き、記事ごとのマークアップ、切り替えと戻し方
  - 再現できずに捨てた指摘は無い
- 2026-10-09: 本文を 001 から 002 へ移した
- 2026-10-09: Cloud SQL のインスタンスが他のサービスと相乗りだと分かった（ユーザー談）。背景の 2 を「固定費」から「共有 DB への攻撃面」に書き換え、後始末でインスタンスを止めないようにした
