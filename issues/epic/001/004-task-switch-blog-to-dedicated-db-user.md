# 004 (task): 乗り換えまでの間、ブログを `lokka_production` だけを触れる DB ユーザーへ切り替える

起票日: 2026-10-09

## 概要

ブログは EOL の Ruby 2.6 / DataMapper のまま、他のサービスと相乗りの Cloud SQL（`hoby-db`）に `koji` ユーザーで接続している（README の `DATABASE_URL`）。
`koji` が他のサービスの DB にも権限を持っていると、ブログが破られたときに他のサービスのデータまで届く。
乗り換え（epic 001）が終わるまでの間、ブログの接続を `lokka_production` だけに権限を持つ専用ユーザーへ替え、攻撃が届く範囲を狭める。

**着手の条件**: 003 の `SHOW GRANTS` で、`koji` が `lokka_production` 以外にも届くと分かったとき。届かないなら、この issue は不要として閉じる。

## 対応方針

1. 専用ユーザーを作る

   ```sql
   CREATE USER 'lokka'@'%' IDENTIFIED BY '<生成した長いパスワード>';
   GRANT SELECT, INSERT, UPDATE, DELETE ON lokka_production.* TO 'lokka'@'%';
   ```

   - DataMapper の `auto_upgrade!` は起動時に呼ばれていない（`Lokka::Database#connect` は `DataMapper.setup` だけ。`migrate` は rake からだけ呼ばれる）ので、DDL の権限は要らない見込み。**未確認**なので、切り替えた後に記事の表示と管理画面での保存を 1 回ずつ確かめる
2. Cloud Run の `DATABASE_URL` を新しいユーザーに替えて、デプロイし直す
   - パスワードはできれば Secret Manager に置く（README の TODO にもある）
3. 表示・ログイン・記事の保存を確かめる。だめなら、前のリビジョンへトラフィックを戻す
4. `koji` のパスワードを替えるかどうかは、他のサービスの都合に合わせて決める（ブログの古い env に残っているため）

## 関連

- 003 — 着手の条件を決める権限の確認
- 011 — 乗り換え後の後始末（このユーザーを消す）

## 進捗

- 2026-10-09: 起票（003 の結果待ち）
