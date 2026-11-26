# 005 (design): 配信先・静的サイトの生成ツール・CMS・repo の置き方を決める

起票日: 2026-10-09

## 概要

乗り換え（epic 001）の土台を 4 つ決める。006〜010 はここで決めた前提で作る。

## 現在の選択と未決定項目

| 項目 | 推奨 | 理由 |
|---|---|---|
| 配信先 | **Cloudflare Pages** | 静的配信は無料で上限なし。`blog.jiikko.com` はサブドメインなので、Route 53 に CNAME を置くだけで使え、ネームサーバーの移管は要らない（[Cloudflare のドキュメント](https://developers.cloudflare.com/pages/configuration/custom-domains/)。apex ドメインのときだけ Cloudflare のゾーンが必要）。push でビルドとデプロイまで自動 |
| 生成ツール | **Hugo** | 単一バイナリで、Node の依存を持たない。乗り換えの動機の 1 つが「upgrade がめんどう」なので、依存の追従が最も少ないものを選ぶ。テーマは ERB 4 枚（layout / entries / entry / 404）なので Go テンプレートへの移植は軽い |
| CMS | **Sveltia CMS** | `static/admin/` に HTML 1 枚と `config.yml` を置くだけで、管理画面の UI（一覧・エディタ・プレビュー・画像）が出る。保存すると repo に commit される |
| CMS の認証 | 最初は **GitHub の個人アクセストークン** | 書き手は 1 人なので、OAuth の中継（`sveltia-cms-auth` の Cloudflare Worker）は要らない（[sveltia-cms-auth](https://github.com/sveltia/sveltia-cms-auth) の README も、1 人ならトークンが簡単としている）。fine-grained トークンで、この repo の contents の書き込みだけに絞り、有効期限を付ける。トークンはブラウザに保存されるので、漏れたときに届くのはその repo だけ、という範囲に抑えるのが目的 |
| repo | **既存 repo に段階移行** | 2026-11-18 に既存 repo で Hugo 化を開始。DB の記事を書き出すまで Lokka のソースとテーマを参照用に残し、その後に不要な実行コードを整理する |

Astro / Jekyll を選ばない理由: どちらも Node か Ruby のツールチェーンの追従が要る。Pages CMS を選ばない理由: 管理画面がブログのドメインではなく Pages CMS 側になる。

## 決めること

- [x] 静的サイトの生成ツール: **Hugo**（2026-11-18 に選択）
- [x] 既存 repo に段階的に移植する（2026-11-18 に着手。DB 書き出しまで Lokka のソースとテーマを参照用に残す）
- [x] 配信先: **Cloudflare Pages**（2026-11-26 に決定）。GitHub Pages を採らない理由: 独自ドメインを付ける前は `jiikko.github.io/blog/` のサブパスでしか出ず、今の URL の形のまま切り替え前に確かめられない。サーバー側のリダイレクト（`_redirects` の 301）も無い
- [x] repo は public のままにする（2026-11-26 に決定）。public の fork は private にできないが、静的サイトの repo に秘密は入らない（CMS のトークンはブラウザに保存される）。代わりに、下書きを repo に置かない（`draft: true` でも GitHub では読める）
- [ ] CMS と認証方法
- [x] 既存 repo を使う（2026-11-18 に Hugo 化を開始。新しい repo を作る案は採らない）
- [ ] **新しい記事の URL の形**（009 の前に決める）。CMS は連番の id を振れない見込みなので、slug（`/<slug>`）か日付の形にする。slug にするなら、既存の数字の URL・`/resque`・`/category/` `/tags/` `/page/` `/admin/` `/index.atom` `/sitemap.xml` と衝突しないことをビルドで検査する

## 確かめたこと

- Cloudflare Pages の `_redirects` は、照合の元にクエリ文字列を使えない（[公式のリダイレクトの説明](https://developers.cloudflare.com/pages/configuration/redirects/) では、元はファイルパスだけ。[Hugo のフォーラムの議論](https://discourse.gohugo.io/t/cloudflare-pages-redirect-based-on-query-string/52439) も同じ結論）。旧 `/?page=N` の扱いは 008 で決める
- `sveltia-cms-auth` の README には、GitHub がクライアント側の PKCE に対応すれば中継が要らなくなる、とある。対応したかは**未確認**

## 進捗

- 2026-10-09: 起票（推奨を置いた。ユーザーの決定待ち）
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した
- 2026-11-26: 配信先を Cloudflare Pages に、repo を public のままにすると決めた（ユーザー決定）。`gh repo view` で public の fork であること、`gh api .../actions/permissions` で Actions が有効なことを確かめた
