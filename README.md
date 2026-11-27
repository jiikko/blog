# blog.jiikko.com

`https://blog.jiikko.com` のソース。Hugo で静的サイトを作り、Cloudflare Pages（プロジェクト `blog`、`https://blog-9oc.pages.dev`）で配信している。

もとは Lokka（Ruby。Cloud Run と Cloud SQL で動かしていた）の fork だった。テーマと公開記事 173 件を issue 006〜008 で移し、2026-11-26 に DNS を切り替えた（issue 010）。Lokka のコードと GCP の資源は issue 011 で消した。テーマは Lokka 同梱の `jarvi` テーマから作られているので、Lokka の `LICENSE` を残している。

## 手元で見る・ビルドする

Hugo 0.170 以降を入れる（`brew install hugo`。CI と Cloudflare Pages は 0.170.0）。手元で見るには次を打ち、表示された URL を開く。

```sh
hugo server --buildDrafts
```

サイトを作るには次を打つ。出力は `dist/` に書かれる。

```sh
hugo --minify
```

## ビルドと公開の仕組み

- GitHub Actions（`.github/workflows/hugo.yml`）は、Hugo 0.170.0 の `hugo --gc --minify` を走らせる。走るのは `blog.jiikko.com` ブランチへの push・そのブランチ宛ての PR・手動の実行のとき。ビルドが通るかを確かめるだけで、公開はしない
- Cloudflare Pages は、同じブランチへの push のたびに同じコマンドでビルドし（出力 `dist`、環境変数 `HUGO_VERSION=0.170.0`）、公開する
- Pages の環境変数 `SKIP_DEPENDENCY_INSTALL=1` は、Lokka のファイルがあった頃に `bundle install` を止めるために入れたもの。今は要らない

## 記事の書き方（更新マニュアル）

Claude Code には「記事を書いて」と頼めばよい。この repo の skill `new-post`（`.claude/skills/new-post/SKILL.md`）が、この節の手順を確かめる段つきで進める。確かめるのは、名前の衝突・ビルド・公開の承認・本番での表示。決まりごとの正本はこの節なので、変えるときはここを直す。

1. 記事のファイルを作る。ファイル名がそのまま URL になる（`content/posts/my-post.md` → `https://blog.jiikko.com/my-post`）

   ```sh
   hugo new content posts/my-post.md
   ```

   - ファイル名は英小文字・数字・`-` で付ける。数字だけの名前（`211` など）は旧ブログの記事と同じ形なので使わない。`page` `category` `tags` `theme` `index` も、既にある URL とぶつかるので使わない
2. front matter を埋めて、本文を Markdown で書く

   ```toml
   +++
   title = "記事の題"
   date = "2026-11-26T23:19:50+09:00"     # 公開日時。記事ページと一覧の日付・並び順になる
   lastmod = "2026-11-26T23:19:50+09:00"  # 直したら更新する（feed と sitemap に出る）
   draft = true                           # 公開するときに false にする
   url = "/my-post.html"                  # 作ったときのまま触らない（/my-post で配信される）
   category = ["4"]                       # カテゴリーの番号。下の表から 1 つ
   tags = ["ruby"]                        # 自由に付ける。大文字小文字は書いたとおりに URL になる
   atom_id = ""                           # 空のままでよい（feed の id は date から作られる。旧ブログの記事だけが旧 feed の id を持つ）
   +++
   ```

   | 番号 | カテゴリー | 番号 | カテゴリー |
   |---|---|---|---|
   | 1 | postfix | 7 | Kinesisキーボード |
   | 2 | dovecot | 8 | shell script |
   | 3 | ruby | 9 | aws |
   | 4 | 日記 | 10 | rails |
   | 5 | instance-email.com | 11 | MySQL |
   | 6 | 開発環境 | | |

   - 新しいカテゴリーを作るときは、`content/category/<新しい番号>/_index.md` に `title` を書く
   - 画像はこの repo に入れない。別の repo `jiikko/cdn` の `images/blog/YYYY/MM/DD/` に push する。本文には `https://raw.githubusercontent.com/jiikko/cdn/master/images/blog/YYYY/MM/DD/<ファイル名>` を貼る
   - コードブロックは色付けしない（旧ブログに合わせている）。生の HTML（埋め込みなど）も書ける
3. 手元で見た目を確かめる

   ```sh
   hugo server --buildDrafts
   ```

   表示された URL を開く。ファイルを保存すると自動で読み直される
4. 公開する。`draft = false` にしてから commit し、`blog.jiikko.com` ブランチに push する

   ```sh
   git add content/posts/my-post.md
   git commit -m "記事: 記事の題" -- content/posts/my-post.md
   git push origin blog.jiikko.com
   ```

   - **この repo は public なので、`draft = true` のまま commit しない**（サイトには出ないが、GitHub では誰でも読める）。書きかけの記事は commit しないで手元で持つ
   - push すると Cloudflare Pages が自動でビルドして公開する。反映まで 1 分もかからない。ビルドの結果は Cloudflare のダッシュボードの Workers & Pages → `blog` → Deployments で見られる
5. 直すときは、本文と `lastmod` を書き換えて同じように commit・push する。`date` と `url` は変えない（`date` を変えると feed で別の記事として扱われることがある）

## 記事のファイルの形式

記事は `content/posts/` に置く。旧ブログの公開記事 173 件は `bin/export-lokka-entries`（使い方は `--help`）で書き出した。このスクリプトは、`lokka_production` の `mysqldump` を手元の MySQL に戻したものを読む。書くのは、記事ごとの Markdown と `content/category/<id>/_index.md`。DB には書き込まない。この repo は public なので、下書きとコメントは書き出していない。書き出しは済んでおり、スクリプトは記事をどう変換したかの記録として残している。前提にしていた Lokka のソースは、issue 011 より前の git の履歴にある。

旧ブログの記事はすべて Markdown（redcarpet。1 件だけ kramdown）で書かれていたので、本文は元の Markdown のまま持っている。旧ブログの記事は、front matter に次も持つ。

- `url`: 旧ブログの URL
- `lokka_id`: 旧ブログの記事の id
- `category`: カテゴリーの id（`/category/<id>/` の URL が変わらない）
- `atom_id`: 旧 feed の Atom の id

旧 URL は次の仕組みで保っている。

- 記事は `/<名前>.html` として出力し、Cloudflare Pages が旧ブログと同じ `/<名前>` で配信する。テンプレートのリンクもこの形にしている
- タグの URL は、大文字小文字を書いたとおりに保つ（`hugo.toml` の `disablePathToLower`）
- 旧ブログの一覧の `?page=N` は、`layouts/baseof.html` の小さな script で `/page/N/` へ送る
- デプロイの後に `bin/check-legacy-urls <サイトの URL>`（使い方は `--help`）を回すと、旧ブログの頃の URL をすべて要求し、200 を返さないものを挙げる

`hugo.toml` は、redcarpet が出していた HTML に合わせるため、Goldmark の引用符などの自動変換（typographer）とコードブロックの色付けを切っている。Markdown の中には生の HTML も書ける。

テンプレートは `layouts/`、テーマの CSS と画像は `static/theme/blog.jiikko.com/` にある。`static/robots.txt` は sitemap の場所を示している。
