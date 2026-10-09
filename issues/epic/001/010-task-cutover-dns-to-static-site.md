# 010 (task): 新しいサイトへ切り替える（DNS の付け替えと戻し方）

起票日: 2026-10-09

## 概要

`blog.jiikko.com` の向き先を、Cloud Run のドメインマッピングから Cloudflare Pages へ替える。
DNS は Route 53 のまま（サブドメインなので、ネームサーバーの移管は要らない。005）。

## 前提

- 006〜009 が終わり、`<project>.pages.dev` で全 URL の確認（008 の受け入れ条件）が済んでいる

## 手順

1. 前日までに、Route 53 の `blog.jiikko.com` の TTL を短くする（例: 300 秒）
2. 今の Lokka で記事を書くのを止める（止めた後に書いた記事は、新しいサイトに無い）
3. `lokka_production` の `mysqldump` を取る（戻すときと、書き出しのやり直しに使う。AWS の鍵が平文で入るので置き場所に気をつける）
4. 書き出し（006）を最後にもう一度走らせて、差分が無いことを確かめる
5. Cloudflare Pages のプロジェクトに、カスタムドメイン `blog.jiikko.com` を追加する（ダッシュボードの手順を通さないと、CNAME だけでは 522 になる）
6. Route 53 で、`blog.jiikko.com` を Pages のホスト名への CNAME に替える。今は Google の IP の A レコードなので、置き換える
7. 証明書が発行されて Active になるのを待ち、008 の URL の確認を本番のドメインでもう一度走らせる
8. Google Search Console に新しい sitemap を出す。Search Console の所有権の確認に DNS の TXT レコードを使っていれば、消さない
9. 🚨 **古い Cloud Run を外から触れなくする**: DNS を替えても `*.run.app` の URL は公開のまま（README のデプロイは `--allow-unauthenticated`）で、古い管理画面と DB への接続が残る。切り替えたらすぐ、`allUsers` の起動権限を外すか ingress を `internal` にする。戻すときだけ開け直す
10. アップロード用の S3 を使っていなければ（003）、`options` に入っている AWS のアクセスキーをこの時点で無効にする

## 戻し方

- Route 53 のレコードを、今の Google の A レコードへ戻す
- Cloud Run のサービスとドメインマッピングは、011 まで残しておく
- 戻すときに備えて、切り替え前のレコードの値をこの issue に控えておく

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した。古い Cloud Run を閉じる手順と、切り替え前の dump を足した
