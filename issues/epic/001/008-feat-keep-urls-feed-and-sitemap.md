# 008 (feat): 今の URL・feed・sitemap を新しいサイトで保つ

起票日: 2026-10-09

## 概要

検索エンジンと外部からのリンク、feed の購読者を失わないように、今の URL の形を新しいサイトでもそのまま出す。
変わるものはリダイレクトする。

## 今の URL（2026-10-09 に本番で確認）

| 種類 | 形 | 末尾のスラッシュ | 件数・備考 |
|---|---|---|---|
| 記事 | `/<id>`（slug があれば `/<slug>`） | **無し**（`/210/` は 404） | 173 件。slug は `/resque` の 1 件 |
| カテゴリー | `/category/<id>/` | **有り**（`/category/4` は 404） | 10 個（2〜11）。親子があれば `/category/<親>/<子>/`（`Category#link`） |
| タグ | `/tags/<名前>/` | 有り | 日本語の名前もある（`/tags/スプラトゥーン/` を URL エンコードした形で 200） |
| 年別 | `/YYYY/` | 有り（`/2025` は 404） | |
| 月別 | `/YYYY/MM/` | 有り | **今の本番で 500**。保つものは無い。作るなら新設 |
| ページ送り | `?page=N`（トップ・カテゴリー・タグ・年別） | — | 範囲外の `?page=19` も 200 で空の一覧を返す |
| feed | `/index.atom` | — | 1 ページ 10 件で、`?page=N` で遡れる（`/index.atom?page=2` も 10 件）。本文は `<!-- more -->` で切った `short_body` |
| sitemap | `/sitemap.xml` | — | トップ + 最新 10 件だけ |
| 検索 | `/search/?query=` | — | テーマに検索フォームが無い。作らない |

## 対応方針

- **記事の `/<id>` をスラッシュ無しで出す**
  - Hugo で `/210.html` のようにファイルを出せば、Cloudflare Pages は `/210` で配信する見込み（拡張子無しの URL を `.html` に当てる。**未確認**。実際にデプロイして確かめる）
  - `/210/` が 404 から 200 やリダイレクトに変わるのは害が無いので、どちらでもよい
- **カテゴリー・タグ・年別はスラッシュ有りのディレクトリで出す**（Hugo の既定に近い）
- **ページ送り**:
  - 新しいサイトでは `/page/N/` の形にする
  - 旧 `?page=N` は、Cloudflare Pages の `_redirects` がクエリ文字列で照合できないので、リダイレクトできない（005 の「確かめたこと」）
  - 旧 URL に来た人には 1 ページ目が出る。検索エンジンの評価は記事ページに付いているので、受け入れる
  - どうしても要るなら、Cloudflare の Worker か Redirect Rules が要る（ゾーンを Cloudflare に移す必要があるかは**未確認**）
- **feed**:
  - `/index.atom` は今と同じパスで出す
  - 各記事の `<id>` は今の文字列をそのまま保つ。今は `tag:https://blog.jiikko.com:443,<created_at の文字列>` という形で、`index.builder` の `gsub('http://', '')` が https を外さないためにこうなっている
  - `<id>` が変わると、feed リーダーで全記事が新着として出直す。006 で元の文字列を front matter に持たせて、それをそのまま使う
  - 件数は今と同じ最新 10 件でよい。旧 `?page=N` の feed は再現しない
  - 本文を今と同じ `<!-- more -->` で切った形にするか、全文にするかを決める
  - リンクの `:443` は付けない（リンクの形が変わるだけで、購読には影響しない見込み）
- **sitemap**: 全記事・カテゴリー・タグを載せる（今は 10 件だけなので、むしろ改善になる）

## 切り替えの前に `pages.dev` で確かめること

- 拡張子無しの `/210` で `210.html` が出るか、`/210/` がどうなるか、日本語のタグのディレクトリが出るか。ここが崩れると URL の設計を変えるので、テーマの移植（007）より先に、数ページで試す
- Hugo の設定: 版を `HUGO_VERSION` で固定する、記事の出力を `uglyURLs` か記事ごとの `url` で決める、Cloudflare Pages のビルドコマンドと出力先（`hugo --gc --minify` / `public`）
- Hugo が新しく作る `/tags/` や `/categories/` の一覧ページは、今は無い URL。出しても害は無いので、出すかは任意

## 受け入れ条件

- [ ] 今の本番の全記事 URL（173 件）、全カテゴリー、出現した全タグ、年別の各 URL を、新しいサイトに当てて全部 200 になる（機械で確かめる。一覧は 003 のクロールと同じ方法で取る）
- [ ] 全記事の `<id>` が今の feed と一致する。今の本番の `/index.atom?page=1`〜`?page=18` を取れば 173 件分の `<id>` が揃うので、それと突き合わせる

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した。feed のページ送りと本文、`pages.dev` での事前確認を足した
- 2026-11-26: ユーザーの指示「旧ブログと同じ URL の構成にできるならそうし、できないなら旧 URL からリダイレクトする」で着手した
  - 記事: front matter の `url = "/210.html"` で `210.html` を出し、Cloudflare Pages が拡張子無しの `/210` で配信する（デプロイ後に確かめる）。テンプレート・Atom・sitemap のリンクは `layouts/_partials/post-link.html` / `post-permalink.html` で `.html` を外す。`uglyURLs` はカテゴリーの URL を `/category/4.html` にしたので採らない。`[permalinks.page] posts = "/:contentbasename.html"` はリンクが `/210.html/` になったので採らない
  - タグ: `disablePathToLower = true` で `/tags/ErgodoxEZ/` のように大文字小文字を保つ。日本語のタグもそのままのディレクトリ
  - 年別: `content/years/_content.gotmpl` で 2014〜今年のページを作り、`[permalinks.page] years = "/:title/"` で `/YYYY/` に置く。本番の `?page=N` を辿った件数と一致（2015 年 26 件・2024 年 11 件・2025 年 2 件）。全件を 1 ページに出す
  - ページ送り: 一覧のページ（`.IsPage` でないもの）に、`?page=N` を `/page/N/` へ送る JavaScript を入れた（サーバー側はクエリ文字列でリダイレクトできない）。範囲外の N は 404 になる（本番は空の一覧で 200）
  - feed: 最新 20 件（本文は全文）。`<id>` は front matter の `atom_id`。リンクは拡張子無し
  - sitemap: `layouts/sitemap.xml` で全ページ（記事は拡張子無し）
  - `bin/check-legacy-urls <origin>` を作った: content/ から旧 URL（記事 173・カテゴリー 11・使われているタグ・年 2014〜今年・`/index.atom`・`/sitemap.xml`、計 227 件）を作り、リダイレクトを辿らずに 200 かを見る。較正: 今の本番では 227 件すべて 200。記事を入れる前の pages.dev では 225 件が 404（Atom と sitemap だけ 200）。Cloudflare は Python の既定の User-Agent に 403 を返すので、User-Agent を付けている
- 2026-11-26: ed9aa9e を push し、Cloudflare Pages のデプロイ後に確かめた
  - `bin/check-legacy-urls https://blog-9oc.pages.dev`: **227 件すべて 200**（rc=0）。拡張子無しの `/210` が `210.html` で配信されることを確かめた（見込みだった点）
  - `/210/` と `/210.html` は `/210` へ 308。`/page/2/`・`/tags/`・`/category/` は 200（`/tags/` と `/category/` は本番では 404 の URL。出して害は無い）
  - 日本語のタグ `/tags/スプラトゥーン/` は 200 で、題も正しい
  - Chrome で `/?page=3` → `/page/3/`、`/category/4/?page=2` → `/category/4/page/2/` に送られることを確かめた
  - 受け入れ条件 1 は満たした。2（全記事の `<id>` が旧 feed と一致）は、最新 20 件の `<id>` を front matter の `atom_id` から出しているところまで。旧 feed の `?page=1`〜`18` との全件の突き合わせはまだ
- 2026-11-26: 年別 `/YYYY/` を消した（ユーザー決定）。旧ブログでは、年別のページ自身のページ送りを除いて、どのページ（トップ・記事・カテゴリー・タグ）・テーマ・記事の本文にも年別へのリンクが無く、旧 sitemap にも載っていなかった。消したので `/2015/` などは 404。`bin/check-legacy-urls` の確認対象からも外した
- 2026-11-26: sitemap と Atom を旧ブログと機械で比べて揃えた
  - sitemap: トップ（`changefreq daily` / `priority 1.0`）+ 全記事を新しい順。旧ブログにあった 11 件（トップ + 最新 10 件）は loc・lastmod・changefreq・priority まで一致。全体は 174 件（記事は 10 件から全件に増やした）。カテゴリー・タグの一覧は載せない（旧ブログと同じ）
  - `lastmod` と Atom の日時: 旧ブログは DB の値に `+00:00` を付けて出していた。Hugo は同じ値を Asia/Tokyo として読み `+09:00` を付けていたので、指す時刻が 9 時間ずれていた。`layouts/_partials/lokka-time.html` で旧ブログと同じ文字列にした
  - **Atom が XML として壊れていた**（テーマの移植のときから。先頭の `<?xml` を Hugo が `&lt;?xml` にエスケープしていた。これまでの確認は 200 かどうかだけだった）。直した
  - Atom: フィードの `<id>`（`https://blog.jiikko.com:443/`）・`<updated>`（最新記事の更新日時）・件数 10・各記事の `<author><name>koji</name></author>` を旧ブログに揃えた。最新 10 件の id・published・updated・title・link・author が全件一致
  - 旧ブログで 404 だった `/posts/`・`/category/`・`/tags/` は作らない（`content/<name>/_index.md` の `build.render = "never"`）
