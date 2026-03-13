---
name: accept-worktree
description: ワークツリー作業の受け入れ評価。機械的検証・Issue受け入れ基準・成果物妥当性の3層で評価し、ACCEPT/CONDITIONAL ACCEPT/REJECTを判定する。
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cd:*), Bash(mise:*), Bash(golangci-lint:*), Bash(goimports:*), Bash(gofmt:*), Bash(go:*), Bash(npx:*), Bash(test:*), Bash(ls:*), Bash(cat:*), Bash(scripts/*), Read, Glob, Grep, Agent
user-invocable: true
---

# Accept Worktree

ワークツリー上の `/start-implementation` 作業成果物を3層で評価し、受け入れ可否を判定する。

## 使用方法

```
/accept-worktree wt1          # 指定 worktree を評価
/accept-worktree wt1 wt2      # 複数 worktree を順次評価
```

## 評価の3層構造

```
Layer 1: 機械的検証（コマンド実行で PASS/FAIL）
  → テスト・リント・フォーマッタ・レイヤー依存チェック。人間の判断不要

Layer 2: Issue 受け入れ基準照合（Issue body の基準を項目ごとに検証）
  → Issue 固有の受け入れ基準

Layer 3: 成果物の妥当性検証（内容を読んで判断）
  → レイヤー依存・API仕様整合・DBスキーマ整合・ドキュメント整合
```

## 実行フロー

```
Step 0: 環境検出 + コミット履歴取得
  ↓
Step 1: Layer 1 — 機械的検証（1つでも FAIL → 即 REJECT）
  ↓
Step 2: Layer 2 — Issue 受け入れ基準照合
  ↓
Step 3: Layer 3 — 成果物の妥当性検証
  ↓
Step 4: 総合判定 + レポート出力
```

---

## Step 0: 環境検出 + コミット履歴取得

### 0.1: worktree パス特定・存在確認

```bash
WT_ID="${1}"
WT_PATH="/workspace/worktrees/${WT_ID}"
ls -d "${WT_PATH}" 2>/dev/null || echo "ERROR: worktree not found"
```

### 0.2: ベースブランチからの差分取得

```bash
cd "${WT_PATH}"
BASE_COMMIT=$(git merge-base main "worktree-${WT_ID}")
git log --oneline "${BASE_COMMIT}..HEAD"
git diff --stat "${BASE_COMMIT}..HEAD"
```

### 0.3: 対象 Issue 番号の特定

コミットメッセージから Issue 番号を抽出する:

```bash
# 例: "feat(#8): ..." → 8
git log --oneline "${BASE_COMMIT}..HEAD" | grep -oP '#\d+' | sort -u
```

複数 Issue が検出された場合は全てを対象とする。
Issue 番号が検出できない場合はエラー表示して終了。

### 0.4: 変更ファイル一覧の分類

差分ファイルを以下のカテゴリに分類し、後続 Step で参照する:

```bash
git diff --name-only "${BASE_COMMIT}..HEAD"
```

| カテゴリ | パターン |
|---------|---------|
| Domain | `internal/domain/**` |
| Usecase | `internal/usecase/**` |
| Handler | `internal/handler/**` |
| Infra | `internal/infra/**` |
| Frontend | `web/src/**` |
| Docs | `docs/**` |
| Schema | `internal/infra/schema.sql` |
| Config | `go.mod`, `go.sum`, `web/package.json` |

---

## Step 1: Layer 1 — 機械的検証

全項目を自動実行し PASS/FAIL を判定する。**1つでも FAIL なら Layer 2 以降に進まず即 REJECT。**

### 実行手順

以下を `${WT_PATH}` 内で順次実行する:

```bash
cd "${WT_PATH}"

# L1-1: Go テスト
go test ./... 2>&1

# L1-2: golangci-lint
golangci-lint run ./... 2>&1

# L1-3: goimports + gofmt
test -z "$(goimports -l .)" || { echo "FAIL: goimports"; goimports -l .; }
test -z "$(gofmt -l .)" || { echo "FAIL: gofmt"; gofmt -l .; }

# L1-4: レイヤー依存チェック
bash scripts/check-layer-deps.sh 2>&1

# L1-5: TypeScript 型チェック（Frontend 変更がある場合のみ）
# Step 0.4 で Frontend カテゴリに変更がある場合のみ実行
cd "${WT_PATH}/web" && npx tsc --noEmit 2>&1
```

### 判定

| # | チェック | PASS 条件 |
|---|---------|----------|
| L1-1 | Go テスト | 全件 passed |
| L1-2 | golangci-lint | 0 issues |
| L1-3 | goimports + gofmt | 出力なし |
| L1-4 | レイヤー依存チェック | スクリプト正常終了 |
| L1-5 | tsc（Frontend 変更時のみ） | 出力なし |

---

## Step 2: Layer 2 — Issue 受け入れ基準照合

### 2.1: Issue body 取得

```bash
gh issue view ${ISSUE_NUM} --json body,title --jq '{title,body}'
```

### 2.2: 受け入れ基準の抽出

Issue body から以下のセクションを抽出する:
- `## 受け入れ基準` セクション
- `## 品質ゲート` セクション（あれば）

### 2.3: 各基準の検証

基準の性質に応じて検証方法を切り替える:

| 基準の種類 | 検証方法 |
|-----------|---------|
| テスト PASS 系 | L1 結果を参照 |
| ファイル存在系 | `git diff --stat` で確認 |
| インターフェース定義系 | 変更ファイルを読み、定義内容を確認 |
| アーキテクチャ準拠系 | L1-4 結果 + 変更ファイルの import を確認 |

各基準に対して PASS / FAIL / N/A を判定する。

---

## Step 3: Layer 3 — 成果物の妥当性検証

Step 0.4 で分類した変更ファイルのカテゴリに基づき、**変更があるカテゴリのみ** 検証する。変更がないカテゴリは「変更なし — SKIP」とする。

### 3-1: レイヤー依存の妥当性

**対象**: `internal/` 配下の変更ファイル

変更ファイルの import 文を読み、レイヤー依存ルールに違反していないか検証する。

| # | チェック | 判定基準 |
|---|---------|---------|
| LD-1 | `domain` が他の internal パッケージを import していないか | `internal/domain/*.go` の import に `internal/usecase`, `internal/handler`, `internal/infra` が含まれない |
| LD-2 | `usecase` が `domain` のみ import しているか | `internal/usecase/*.go` の import に `internal/handler`, `internal/infra` が含まれない |
| LD-3 | `handler` が `usecase`, `domain` のみ import しているか | `internal/handler/*.go` の import に `internal/infra` が含まれない |
| LD-4 | `infra` が `domain` のみ import しているか | `internal/infra/*.go` の import に `internal/handler`, `internal/usecase` が含まれない |

LD-1〜4 のいずれかに違反がある場合は **REJECT**。

### 3-2: API 仕様整合

**対象**: `internal/handler/**` の変更ファイル

**変更がない場合は SKIP。**

変更された handler のレスポンス構造体・ステータスコードが `docs/api.md` の定義と一致するか検証する。

| # | チェック | 判定基準 |
|---|---------|---------|
| API-1 | レスポンスの JSON フィールド名が api.md と一致するか | 構造体の `json` タグと api.md のレスポンス例を照合 |
| API-2 | エラーレスポンスのステータスコードが api.md と一致するか | handler のエラーハンドリングと api.md のエラー定義を照合 |
| API-3 | 新規エンドポイントの場合、api.md に定義が追加されているか | handler に新しいルートがあるのに api.md に対応する記述がない場合は WARN |

API-1 または API-2 に不一致がある場合は **REJECT**。

### 3-3: DB スキーマ整合

**対象**: `internal/domain/**` または `internal/infra/**` の変更ファイル

**変更がない場合は SKIP。**

domain エンティティのフィールドが `internal/infra/schema.sql` のカラムと対応するか検証する。

| # | チェック | 判定基準 |
|---|---------|---------|
| DB-1 | エンティティ構造体のフィールドが schema.sql のカラムと対応するか | 各フィールドに対応するカラムが存在し、型が妥当か（TEXT→string, INTEGER→int, NULL許容→ポインタ型） |
| DB-2 | JSON 配列カラム（side_effects, views, hooks, acts_as, covers）が `[]string` 型か | domain では Go スライス、DB では JSON 文字列。変換は infra 層の責務 |
| DB-3 | リポジトリ IF のメソッドが CRUD + フィルタに必要なものを網羅しているか | api.md のエンドポイントで必要な操作がリポジトリ IF に存在するか |

DB-1 に不一致がある場合は **REJECT**。

### 3-4: ドキュメント整合

**対象**: コード変更に伴うドキュメントの更新漏れ

| # | チェック | 判定基準 |
|---|---------|---------|
| DOC-1 | 新規エンティティ追加時に `docs/data-schema.md` が更新されているか | domain に新しいエンティティがあるのに data-schema.md に対応する記述がない場合は WARN |
| DOC-2 | 新規エンドポイント追加時に `docs/api.md` が更新されているか | handler に新しいルートがあるのに api.md に対応する記述がない場合は WARN |
| DOC-3 | schema.sql の変更時に関連ドキュメントが更新されているか | テーブル追加・変更があるのに data-schema.md / architecture.md に対応する更新がない場合は WARN |

DOC-1〜3 は **WARN**（REJECT ではない）。

---

## Step 4: 総合判定 + レポート出力

全 Layer の結果を集約し、以下のフォーマットでレポートを出力する。

```markdown
## 受け入れ評価: worktree-${WT_ID} (Issue #${ISSUE_NUM})

### Layer 1: 機械的検証

| # | 項目 | 結果 |
|---|------|------|
| L1-1 | Go テスト | PASS / FAIL |
| L1-2 | golangci-lint | PASS / FAIL |
| L1-3 | goimports + gofmt | PASS / FAIL |
| L1-4 | レイヤー依存チェック | PASS / FAIL |
| L1-5 | tsc（Frontend 変更時のみ） | PASS / FAIL / SKIP |

### Layer 2: Issue 受け入れ基準

| # | 基準 | 結果 | 備考 |
|---|------|------|------|
| L2-1 | (Issue から抽出した基準1) | PASS / FAIL | |
| L2-2 | ... | ... | |

### Layer 3: 成果物の妥当性

| カテゴリ | 結果 | 指摘事項 |
|---------|------|---------|
| 3-1 レイヤー依存 | PASS / SKIP / REJECT | 指摘内容 |
| 3-2 API 仕様整合 | PASS / SKIP / REJECT | 指摘内容 |
| 3-3 DB スキーマ整合 | PASS / SKIP / REJECT | 指摘内容 |
| 3-4 ドキュメント整合 | PASS / SKIP / WARN | 指摘内容 |

### 総合判定: **ACCEPT / CONDITIONAL ACCEPT / REJECT**

#### 受け入れ前に対応が必要な項目（CONDITIONAL ACCEPT / REJECT の場合）
1. ...
2. ...

#### 所感
(全体的な評価コメント)
```

### 判定基準

| 判定 | 条件 |
|------|------|
| **ACCEPT** | Layer 1-3 全て PASS（SKIP 含む） |
| **CONDITIONAL ACCEPT** | Layer 1-2 は PASS、Layer 3 に WARN のみ（修正推奨だが再評価不要） |
| **REJECT** | Layer 1 に FAIL あり、または Layer 2-3 に REJECT あり |

---

## 禁止事項

- ワークツリー内のファイル編集・コミット・プッシュ
- Issue のクローズ
- REJECT 項目の自動修正（報告のみ。修正はワーカーまたはユーザーが行う）

## 注意事項

- Layer 3 の検証には docs/ や schema.sql の読み込みが必要。Agent を活用して並列に調査してよい
- 複数 worktree を評価する場合は順次実行する（並列実行しない）
