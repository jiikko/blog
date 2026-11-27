---
name: new-post
description: blog.jiikko.com (この repo の Hugo のサイト) に新しい記事を書いて公開する。記事のファイルを hugo new で作り、カテゴリーとタグを既存のものに合わせ、名前が既存の URL とぶつからないこととビルドが通ることを確かめ、ユーザーの承認を得てから draft = false にして commit・push し、本番で記事が開けることを確かめる。「記事を書いて」「ブログに書いて」「新しい記事」「new-post」で発火。既存の記事を直すだけのときも 5〜7 を使う。
---

# 新しい記事を書く

記事の決まりごと (front matter の各項目・カテゴリーの番号・画像の置き場・使わない名前・`date` と `url` を変えない理由) の正本は
`README.md` の「記事の書き方（更新マニュアル）」。**始める前にその節を Read する**。この skill はその手順を、確かめる段つきで進めるためのもの。

## 1. 中身と名前を決める

- 題・本文の材料・カテゴリー・タグ・画像の有無をユーザーに聞く。足りないものだけを聞き、本文をこちらで膨らませない
- 名前 (ファイル名 = URL) を決める。README の規則 (英小文字・数字・`-`、数字だけにしない、使わない名前) に従い、次で確かめる。何も出なければよい

  ```sh
  name=my-post
  printf '%s\n' "$name" | grep -Ev '^[a-z0-9-]+$' && echo "使えない字がある"
  printf '%s\n' "$name" | grep -E '^[0-9]+$' && echo "数字だけの名前は旧ブログの記事と同じ形"
  case "$name" in page|category|tags|theme|index) echo "既にある URL とぶつかる";; esac   # README の「使わない」名前と同じにしておく
  ls content/posts/"$name".md 2>/dev/null && echo "同じ名前の記事がある"
  ```

## 2. カテゴリーとタグを既存に合わせる

- カテゴリーは既存から 1 つ選ぶ。一覧は `grep -H '^title' content/category/*/_index.md`。どれにも合わないときだけ、新しい番号の `_index.md` を作る (ユーザーに確かめてから)
- タグは、同じ意味の既存のタグがあればその綴りを使う (大文字小文字がそのまま URL になるので、`Ruby` と `ruby` を作り分けない)。一覧は

  ```sh
  grep -h '^tags = ' content/posts/*.md | grep -o '"[^"]*"' | sort | uniq -c | sort -rn
  ```

## 3. ファイルを作って書く

```sh
hugo new content posts/"$name".md
```

- 雛形 (`archetypes/posts.md`) が `date`・`lastmod`・`url`・`draft = true` を埋める。`title`・`category`・`tags` を書き、本文を Markdown で書く
- 画像は README のとおり `jiikko/cdn` に置く。push はユーザーに頼むか、承認を取ってから行う (別の repo への公開になる)

## 4. ビルドと見た目を確かめる

```sh
out="$PWD/tmp/new-post-$(date +%Y-%m-%d)"; mkdir -p "$out"
hugo --buildDrafts -d "$out/dist" > "$out/build.log" 2>&1; echo rc=$?
grep -E 'WARN|ERROR' "$out/build.log"; ls "$out/dist/$name.html"
```

- rc=0 で、`build.log` に `WARN` / `ERROR` が無く、`$out/dist/<name>.html` ができていること
- 見た目はユーザーに `hugo server --buildDrafts` で開いてもらう (表示された URL の `/<name>`)

## 5. 公開する (ユーザーの承認を得てから)

公開は誰でも読める場所への公開なので、**題・URL・カテゴリー・タグを示して承認を取ってから**進める。

1. `draft = false` にする。公開の日時を書いた日時にしたいなら `date` と `lastmod` を今の日時に直す (公開した後は `date` を変えない)
2. 下書きのまま commit しない (README の注意)。`grep -n '^draft' content/posts/"$name".md` が `draft = false` であることを見てから commit する
3. 記事のファイル (と、作ったならカテゴリーの `_index.md`) だけを pathspec で commit して push する

   ```sh
   git add content/posts/"$name".md
   git commit -m "記事: <題>" -- content/posts/"$name".md
   git push origin blog.jiikko.com
   ```

## 6. 本番で確かめる

- Cloudflare Pages のデプロイの結果を待つ: `gh api repos/jiikko/blog/commits/$(git rev-parse HEAD)/check-runs --jq '.check_runs[] | "\(.name) \(.status) \(.conclusion)"'` で `Cloudflare Pages completed success` が出るまで (1 分もかからない)
- `curl -s -o /dev/null -w '%{http_code}\n' -A check https://blog.jiikko.com/"$name"` が 200
- トップ (`https://blog.jiikko.com/`) の先頭に記事が出ていること
- 旧ブログの URL を壊していないことを `bin/check-legacy-urls https://blog.jiikko.com` で見る (215 件すべて 200)

## 7. 直すとき

本文と `lastmod` を書き換え、4 と 5 の 2・3 と 6 を同じように行う。`date` と `url` は変えない。
