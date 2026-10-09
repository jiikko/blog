# 003 (human): 本番 DB の中身と `koji` ユーザーの権限を確かめる

起票日: 2026-10-09
期限: 2026-10-16

## 概要

乗り換え（epic 001）の書き出しと後始末を決めるために、本番 DB で次の SQL を実行して結果をこの issue に貼ってほしい。

## 人がやる理由

Claude には本番 DB への経路が無い。手元の `gcloud` にはアカウントが設定されておらず（2026-10-09 確認）、DB のパスワードも手元に無い。
公開ページから数えられるものは、2026-10-09 にクロールして数えた（下の「公開ページから分かったこと」）。ここに残したのは、DB を見ないと分からないものだけ。

## TODO（着手するとき）

- [ ] **DB への接続方法は、着手するときにユーザーが Claude へ渡す**（2026-10-09 のユーザーの指示）。それまで Claude は、gcloud のログイン・パスワードの取り出し・proxy の用意を自分で進めない
- [ ] 接続方法をもらったら、下の SQL を Claude が流して結果をここに貼る（SELECT だけ。`options` の値とパスワードのハッシュは出さない）
- [ ] 2 の記法ごとの件数で、006 の書き出しの形を決める（下の「進捗」の 2026-10-09 の方針）

## 手順

Cloud SQL Studio か `gcloud sql connect` で `hoby-db` に入り、次を実行する。

```sql
-- 1. 権限: koji が他のサービスの DB にも届くか（004 の要否が決まる）
SHOW GRANTS FOR CURRENT_USER();
SELECT user, host FROM mysql.user;   -- ブログ専用のユーザーが既にあるか

USE lokka_production;

-- 2. 記事の内訳
SELECT type, draft, COUNT(*) FROM entries GROUP BY type, draft;          -- Page の有無・下書きの数
SELECT markup, COUNT(*) FROM entries GROUP BY markup;                    -- マークアップの内訳
SELECT id, type, slug, title FROM entries WHERE slug IS NOT NULL AND slug <> '';  -- slug を持つ記事

-- 3. 日時のずれ（feed で published が updated より後になる記事がある）
SELECT id, created_at, updated_at FROM entries WHERE created_at > updated_at ORDER BY id DESC LIMIT 10;
SELECT @@global.time_zone, @@session.time_zone;

-- 4. タグ・カテゴリー
SELECT taggable_type, COUNT(*) FROM taggings GROUP BY taggable_type;
SELECT id, slug, title, parent_id FROM categories;

-- 5. options に入っているもの（値は貼らず、名前と空かどうかだけ）
SELECT name, value IS NULL OR value = '' AS empty FROM options;

-- 6. アップロード画像の S3 を本文が参照しているか
SELECT COUNT(*) FROM entries WHERE body LIKE '%amazonaws.com%';

-- 7. その他のデータの有無
SELECT (SELECT COUNT(*) FROM snippets) snippets, (SELECT COUNT(*) FROM field_names) field_names,
       (SELECT COUNT(*) FROM fields) fields, (SELECT COUNT(*) FROM comments) comments, (SELECT COUNT(*) FROM users) users;
```

🚨 `options` の値（AWS の秘密鍵が平文で入っている）と、`SHOW GRANTS` に出るパスワードのハッシュは issue に貼らない。

## 期待値と、違ったときの扱い

- `SHOW GRANTS` が `ON *.*`（全 DB）や他のサービスの DB を含む → 004 を急ぐ
- `lokka_production` だけなら → 004 は不要。done へ送る
- Page が 1 件以上ある → 006 の書き出しと 008 の URL に Page を含める
- 下書きがある → 006 で書き出すか捨てるかを決める
- `created_at > updated_at` の記事が多い、または created_at だけが JST に見える → 006 で日時を補正する
- `options` に `permalink_enabled` があり値が `true` → 記事の URL が日付の形に変わる設定なので、006 と 008 の URL を見直す（本番の URL は `/210` の形なので、無効の見込み）
- `amazonaws.com` を含む記事が 0 件 → アップロード用の S3 は使われていない。011 で AWS の鍵を消すだけで済む

## 公開ページから分かったこと（2026-10-09 のクロール。DB は見ていない）

- 公開記事 173 件。URL は数字の id が 172 件、slug が 1 件（`/resque`）
- カテゴリーは 10 個（`/category/2/`〜`/category/11/`。記事数は 4 が 83 件、3 が 47 件、10 が 18 件、ほかは 1〜5 件）
- タグは使われている（ruby 30 件、rails 15 件、スプラトゥーン 12 件など。日本語のタグもある）
- 本文の画像の置き場所は、`raw.githubusercontent.com` 3 件（どれも別の repo `jiikko/cdn`）、data URI 2 件、`github.com` / `pbs.twimg.com` 各 1 件、Amazon の広告画像 2 件。**アップロード用の S3 を指す画像は 1 枚も無かった**
- iframe は Amazon アフィリエイト 18 件、YouTube 2 件
- `<pre>` を含む記事は 90 件

## 進捗

- 2026-10-09: 起票
- 2026-10-09: 反証レビュー 2 本（事実の照合 / 計画の抜けと順序）の指摘を、コードと本番で確かめてから反映した
- 2026-10-09: ユーザーから DB に繋いでよいと言われた。接続方法は着手時にユーザーが渡す（TODO 節）。あわせて書き出しの方針を変えた。Markdown（kramdown / redcarpet）の記事は描画済みの HTML ではなく元の Markdown（`raw_body`）で渡し、CMS で Markdown のまま直せるようにする。Hugo（Goldmark）で描画した結果を本番のページと機械で比べて、ずれた記事だけ描画済みの HTML にする。Textile と HTML の記事は描画済みの HTML のまま（006）
