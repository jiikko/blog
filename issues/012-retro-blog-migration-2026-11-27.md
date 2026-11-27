# 012 (retro): ブログの移行（Lokka → Hugo + Cloudflare Pages）の振り返り

起票日: 2026-11-27

## どこで踏んだか

1. **持ち込んだ issues/README.md のリンクが、この repo では切れていた**。dotfiles の `issues/README.md` を写した（skill `start-issues-ops`）ときの相対リンク（`../_claude/issue-rules.md`・`../docs/issues-viewer-spec.md`）がそのまま残り、`issue_done.sh` の着手前のリンク検査で止まった。その場で、リンクではない名前だけの参照に直した
2. **外部サービスの手順を記憶で答えた**。fork の解除は GitHub Support が要ると説明したが、ドキュメントを開くと Settings の「Leave fork network」で自分で外せた
3. **Atom が XML として壊れたまま、旧 URL の検査を通っていた**。検査は 200 かどうかだけを見ていた。`bin/check-legacy-urls` に XML として読めるかの検査を足して直した
4. **gcloud のドメインマッピングの操作は beta のコンポーネントにしか無かった**。非対話のシェルでは入れられないので、Cloud Run の REST API を直接呼んだ

## 提案

- 1: 写す元を直す。dotfiles の `issues/README.md` の相対リンクを、どの repo に写しても切れない形（`~/dotfiles/...` の名前だけの参照）にするか、`start-issues-ops` が写すときに書き換える → **dotfiles の新規 issue**（ユーザーの判断待ち）
- 2: 却下: 既存の rule `measure-external-cli-streams-separately.md` の「記憶にある道具の挙動も同じく仮説」に入っている。今回は手を動かす前にドキュメントを読んで気づけた
- 3: 却下: 既存の rule `verify-execution-not-just-exit-code.md`（200 は中身が正しい証拠にならない）に入っている。この repo では検査を直した
- 4: 局所的（gcloud の CLI の都合）。この repo ではもう使わないので直さない
