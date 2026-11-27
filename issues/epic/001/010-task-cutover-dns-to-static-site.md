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
- 2026-11-26: 着手（ユーザーの指示「DNS の切り替えやって」）
  - 切り替え前の Route 53（ホストゾーン `jiikko.com.` `Z08016334XYBKITOC2DN`）の `blog.jiikko.com.`。**戻すときはこの 8 本に戻す**
    - A（TTL 60000）: `216.239.32.21` `216.239.34.21` `216.239.36.21` `216.239.38.21`
    - AAAA（TTL 60000）: `2001:4860:4802:32::15` `2001:4860:4802:34::15` `2001:4860:4802:36::15` `2001:4860:4802:38::15`
    - 起票時の想定（A だけ）と違い、AAAA もある。CNAME は同じ名前の A / AAAA と共存できないので、切り替えでは 8 本を消して CNAME 1 本にする
  - 手順 1: 23:30 JST に A と AAAA の TTL を 60000 → 300 に下げた（値は変えていない。change `C037140520ICWRJAV0J94`）。60000 秒でキャッシュされた分は 2026-11-27 16:10 JST 頃まで残る
  - 手順 5: Cloudflare Pages のプロジェクト `blog` にカスタムドメイン `blog.jiikko.com` を登録した（「My DNS provider」→ CNAME `blog` → `blog-9oc.pages.dev`。状態は Initializing）。旧ブログはそのまま出ている
  - 手順 2〜4: 旧ブログの最後の記事は 2026-04-10。dump は 2026-11-26 21:45 に取り、書き出しは同じ dump から作った
- 2026-11-26 23:53 JST: 切り替えた（ユーザーの判断で、TTL のキャッシュが切れる 11/27 16:10 を待たずに実行）
  - 手順 6: Route 53 で A 4 本・AAAA 4 本を消し、CNAME `blog.jiikko.com.` → `blog-9oc.pages.dev`（TTL 300）を 1 つの変更で作った（change `C02685522TA8V1D6FI784`、INSYNC を確認）
  - 権威 DNS は 10 秒以内に CNAME を返した。1.1.1.1 / 8.8.8.8 / 9.9.9.9 も新しいサイトを返す。古い A をキャッシュしているリゾルバー（このマシンも）は 11/27 16:10 頃まで旧ブログを返しうる
  - 手順 7: Cloudflare のカスタムドメインは約 6 分で Active になり、証明書も有効。`bin/check-legacy-urls https://blog.jiikko.com` を Cloudflare の IP に直接つないで回し、**215 件すべて 200**（Atom と sitemap は XML として読める）。配信元は `server: cloudflare`
  - **戻し方**: `aws route53 change-resource-record-sets --hosted-zone-id Z08016334XYBKITOC2DN --change-batch file://...` に、CNAME を DELETE して上の A 4 本・AAAA 4 本（TTL 300）を CREATE する変更を渡す（作業中は `tmp/dns-2026-11-26/rollback.json` に用意した。tmp は消えるので、上の値から作り直せるように値をここに残している）。旧 Cloud Run はそのまま動いている
  - 残り: 手順 8（Search Console に新しい sitemap を出す。人の作業）、手順 9（旧 Cloud Run の公開を閉じる。戻せる期間との兼ね合いでユーザーに確認する）。手順 10 は 003 で `options` に AWS の鍵が無かったので不要
- 2026-11-27 18:37 JST: 手順 9 を済ませた（ユーザーの指示「16:10 以降に閉じていいよ」）
  - 旧 Cloud Run `blog`（asia-northeast1）から `allUsers` の `roles/run.invoker` を外した。IAM のポリシーは空になった。ingress は `all` のまま
  - 約 30 秒後から `https://blog-7hrjn5ej3q-an.a.run.app/` は 403。`https://blog.jiikko.com/` は 200（Cloudflare）のまま
  - **戻すときは DNS の前に開け直す**: `gcloud run services add-iam-policy-binding blog --region asia-northeast1 --member=allUsers --role=roles/run.invoker`（ドメインマッピング経由のアクセスも同じ権限が要る）
  - 残り: 手順 8（Search Console。人の作業）
