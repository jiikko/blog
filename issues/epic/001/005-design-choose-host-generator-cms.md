# 005 (design): 配信先・静的サイトの生成ツール・CMS・repo の置き方を決める

起票日: 2026-10-09

## 概要

乗り換え（epic 001）の土台を 4 つ決める。006〜010 はここで決めた前提で作る。

## 推奨（決定前）

| 項目 | 推奨 | 理由 |
|---|---|---|
| 配信先 | **Cloudflare Pages** | 静的配信は無料で上限なし。`blog.jiikko.com` はサブドメインなので、Route 53 に CNAME を置くだけで使え、ネームサーバーの移管は要らない（[Cloudflare のドキュメント](https://developers.cloudflare.com/pages/configuration/custom-domains/)。apex ドメインのときだけ Cloudflare のゾーンが必要）。push でビルドとデプロイまで自動 |
| 生成ツール | **Hugo** | 単一バイナリで、Node の依存を持たない。乗り換えの動機の 1 つが「upgrade がめんどう」なので、依存の追従が最も少ないものを選ぶ。テーマは ERB 4 枚（layout / entries / entry / 404）なので Go テンプレートへの移植は軽い |
| CMS | **Sveltia CMS** | `static/admin/` に HTML 1 枚と `config.yml` を置くだけで、管理画面の UI（一覧・エディタ・プレビュー・画像）が出る。保存すると repo に commit される |
| CMS の認証 | 最初は **GitHub の個人アクセストークン** | 書き手は 1 人なので、OAuth の中継（`sveltia-cms-auth` の Cloudflare Worker）は要らない（[sveltia-cms-auth](https://github.com/sveltia/sveltia-cms-auth) の README も、1 人ならトークンが簡単としている）。fine-grained トークンで、新しい repo の contents の書き込みだけに絞り、有効期限を付ける。トークンはブラウザに保存されるので、漏れたときに届くのはその repo だけ、という範囲に抑えるのが目的 |
| repo | **新しい repo**（例: `jiikko/blog-site`） | 今の repo は Lokka の fork で、コード・テーマ・Docker が混ざっている。記事と Hugo だけの repo にすれば、CMS が触る範囲と Pages のビルド対象が単純になる。今の repo は書き出しスクリプト（006）を動かす場所として残し、後始末（011）で archive する |

Astro / Jekyll を選ばない理由: どちらも Node か Ruby のツールチェーンの追従が要る。Pages CMS を選ばない理由: 管理画面がブログのドメインではなく Pages CMS 側になる。

## 決めること

- [ ] 上の推奨でよいか（変えるなら理由を書く）
- [ ] 新しい repo の名前と、公開か非公開か（Pages はどちらでもビルドできる見込み。**未確認**。repo を作る前に確かめる）
- [ ] **新しい記事の URL の形**（009 の前に決める）。CMS は連番の id を振れない見込みなので、slug（`/<slug>`）か日付の形にする。slug にするなら、既存の数字の URL・`/resque`・`/category/` `/tags/` `/page/` `/admin/` `/index.atom` `/sitemap.xml` と衝突しないことをビルドで検査する

## 確かめたこと

- Cloudflare Pages の `_redirects` は、照合の元にクエリ文字列を使えない（[公式のリダイレクトの説明](https://developers.cloudflare.com/pages/configuration/redirects/) では、元はファイルパスだけ。[Hugo のフォーラムの議論](https://discourse.gohugo.io/t/cloudflare-pages-redirect-based-on-query-string/52439) も同じ結論）。旧 `/?page=N` の扱いは 008 で決める
- `sveltia-cms-auth` の README には、GitHub がクライアント側の PKCE に対応すれば中継が要らなくなる、とある。対応したかは**未確認**

## 進捗

- 2026-10-09: 起票（推奨を置いた。ユーザーの決定待ち）
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した
