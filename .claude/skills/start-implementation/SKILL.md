---
name: start-implementation
description: Issue 番号を指定して Plan 策定・実装・テスト・レビュー・コミットを Step 分離エージェントで実行する。
allowed-tools: Bash(gh:*), Bash(git:*), Bash(go:*), Bash(mise:*), Bash(npm:*), Bash(cd:*), Bash(export:*), Read, Glob, Grep, Task, AskUserQuestion
user-invocable: true
---

# Start Implementation

Issue 番号を指定して、Step 分離されたエージェント群による実装を実行する。

## 使用方法

```
/start-implementation #42
/start-implementation 42
```

## アーキテクチャ

```
Skill (オーケストレーター)
  ├─ planner:       Step 2（Issue 読解 + コード探索 → Plan 策定）
  │
  ├─ implementer:   Step 4.3（実装のみ）
  ├─ Skill 自身:    Step 4.4（テスト実行）
  │                   ├─ PASS → 品質ゲートへ
  │                   └─ FAIL → diagnostician へ
  ├─ diagnostician:  Step 4.4a（診断 & 修正計画。実装しない）
  │
  ├─ Skill 自身:    Step 4.5（golangci-lint / goimports / gofmt）
  ├─ reviewer:       Step 4.6（コードレビュー。実装しない）
  └─ Skill 自身:    Step 5（コミット）
```

### 各エージェントの責務

| エージェント | Step | 入力 | 出力 | 禁止事項 |
|---|---|---|---|---|
| planner | 2 | Issue 内容 | Plan ファイル（`/tmp/implementation-plan-{issue番号}.md`） | 推測で Plan を書くこと |
| implementer | 4.3 | Plan / 修正計画 / レビュー指摘 | 「実装完了」報告 | テスト実行、コードレビュー、コミット |
| diagnostician | 4.4a | テスト出力 + 現在のコード | 修正計画（構造化レポート） | 修正の実装 |
| reviewer | 4.6 | base_commit + diff + チェックリスト | レビュー報告 + アクション項目 | 修正の実装 |

### Step 分離の効果

| 問題 | 解決メカニズム |
|---|---|
| Step 4.4a プロトコル違反 | implementer にテスト結果が渡らない。テスト実行は Skill が行うため、自律修正が構造的に不可能 |
| Step 4.6 自己レビュー品質 | reviewer は実装コンテキストを持たない。フレッシュな視点でコードを読む |
| コンテキスト飽和 | 各エージェントは単一 Step のみ実行。コンテキストが小さい |
| テスト合格バイアス | reviewer はテスト結果を知らない状態でレビューする |

## 実行フロー

```
0. 環境検出（ワークツリー判定、REPO_ROOT を設定）
1. Issue 内容取得
2. planner 起動 → Plan ファイル作成
3. Plan 概要報告
4. 実装・検証ループ（implementer → test → diagnostician → quality gate → reviewer）
5. コミット
```

## 環境検出（全 Step の前に実行）

ワークツリー環境かどうかを自動検出し、パスを設定する。
以降の全 Step でこの変数を使用する。

```bash
if [[ "$PWD" =~ worktrees/([^/]+) ]]; then
  WT_ID="${BASH_REMATCH[1]}"
  REPO_ROOT="$PWD"
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo /workspace)"
fi
export DATABASE_URL="postgres://habitrecord:habitrecord@db:5432/habitrecord?sslmode=disable"
```

| 変数 | メイン環境 | ワークツリー環境（例: wt1） |
|------|-----------|---------------------------|
| `REPO_ROOT` | プロジェクトルート | `/workspace/worktrees/wt1` |

## 手順

### Step 1: Issue 内容取得

引数から Issue 番号を抽出し、内容を取得する。

```bash
gh issue view <番号> --json number,title,body,labels
```

Issue 本文から以下を確認:
- 受け入れ基準
- 実装対象のファイルやレイヤー
- テスト計画

### Step 2: Plan 策定（planner）

planner Agent を起動する。
Agent 定義は `.claude/agents/planner.md` を参照。

```
Task:
  subagent_type: general-purpose
  description: "Implementation plan for Issue #XX"
  prompt: |
    あなたは planner です。以下の Agent 定義に従って動作してください。

    <Agent 定義の内容を .claude/agents/planner.md から読み込んで挿入>

    ## 起動パラメータ
    - issue: #XX
    - issue_title: {タイトル}
    - issue_body: |
        {Issue 本文}
    - REPO_ROOT: {REPO_ROOT}
```

Agent は `/tmp/implementation-plan-{issue番号}.md` に Plan を書き出して返却する。

### Step 3: Plan 概要報告

1. Plan ファイルを読み込む:
   ```
   Read: /tmp/implementation-plan-{issue番号}.md
   ```

2. Plan の概要（対象ファイル数、テスト件数、主な変更内容）をユーザーに報告し、自動で Step 4 に進む。

### Step 4: 実装・検証ループ

#### 4.1: 準備

base_commit を記録する:
```bash
cd ${REPO_ROOT} && git rev-parse HEAD
```

初回の input を設定:
```
input = { type: "plan_file", path: "/tmp/implementation-plan-{issue番号}.md" }
```

#### 4.2: ループ開始

以下を全件 PASS + レビュー指摘なしになるまで繰り返す。

---

#### 4.3: implementer 起動

implementer Agent を起動する。
Agent 定義は `.claude/agents/implementer.md` を参照。

input の type に応じて起動パラメータを設定:

```
Task:
  subagent_type: general-purpose
  description: "Implement for Issue #XX"
  mode: bypassPermissions
  prompt: |
    あなたは implementer です。以下の Agent 定義に従って動作してください。

    <Agent 定義の内容を .claude/agents/implementer.md から読み込んで挿入>

    ## 起動パラメータ
    - issue: #XX
    - REPO_ROOT: {REPO_ROOT}

    # input の type に応じて以下のいずれかを渡す:
    # type=plan_file の場合:
    - plan_file: /tmp/implementation-plan-{issue番号}.md

    # type=remediation の場合:
    - remediation: |
        {diagnostician からの修正計画}

    # type=review_fixes の場合:
    - review_fixes: |
        {reviewer からのアクション項目}

    # type=quality_fixes の場合:
    - quality_fixes: |
        {品質ゲートのエラー内容}
```

実装完了報告を待つ。

---

#### 4.4: テスト実行（Skill 自身）

テストを実行する:

```bash
cd ${REPO_ROOT} && go test ./... 2>&1
```

**出力を切り詰めずに記録する**（パイプで `| tail` 等しない）。

分岐:
- **全件 PASS** → 4.5（品質ゲート）へ
- **FAIL あり** → 4.4a（diagnostician）へ

---

#### 4.4a: diagnostician 起動

diagnostician Agent を起動する。
Agent 定義は `.claude/agents/diagnostician.md` を参照。

```
Task:
  subagent_type: general-purpose
  description: "Diagnose test failures for Issue #XX"
  prompt: |
    あなたは diagnostician です。以下の Agent 定義に従って動作してください。

    <Agent 定義の内容を .claude/agents/diagnostician.md から読み込んで挿入>

    ## 起動パラメータ
    - test_output: |
        {テスト実行の全出力}
    - issue_body: |
        {Issue 本文}
    - plan_file: /tmp/implementation-plan-{issue番号}.md
    - REPO_ROOT: {REPO_ROOT}
```

diagnostician からの修正計画を受け取る。
修正計画の概要（分類、FAIL 件数、修正対象ファイル数）をユーザーに報告し、自動で input を設定してループ先頭（4.3）へ戻る:
```
input = { type: "remediation", content: "{diagnostician の修正計画}" }
```

---

#### 4.5: 品質ゲート実行（Skill 自身）

```bash
# 1. リントチェック
cd ${REPO_ROOT} && golangci-lint run ./... 2>&1

# 2. フォーマットチェック
cd ${REPO_ROOT} && test -z "$(goimports -l .)" || { echo "FAIL: goimports"; goimports -l .; exit 1; }
cd ${REPO_ROOT} && test -z "$(gofmt -l .)" || { echo "FAIL: gofmt"; gofmt -l .; exit 1; }
```

分岐:
- **全 PASS** → 4.6（reviewer）へ
- **FAIL** → input を設定してループ先頭（4.3）へ戻る:
  ```
  input = { type: "quality_fixes", content: "{エラー出力}" }
  ```

---

#### 4.6: reviewer 起動

reviewer Agent を起動する。
Agent 定義は `.claude/agents/reviewer.md` を参照。

```
Task:
  subagent_type: general-purpose
  description: "Code review for Issue #XX"
  prompt: |
    あなたは reviewer です。以下の Agent 定義に従って動作してください。

    <Agent 定義の内容を .claude/agents/reviewer.md から読み込んで挿入>

    ## 起動パラメータ
    - base_commit: {base_commit ハッシュ}
    - issue_number: #XX
    - REPO_ROOT: {REPO_ROOT}
```

reviewer からのレビュー報告を受け取る。

**分岐:**

- `fixes_required == false` → ループ終了、完了報告へ
- `fixes_required == true`:
  1. input を設定してループ先頭（4.3）へ戻る:
     ```
     input = { type: "review_fixes", content: "{implementer へのアクション項目}" }
     ```

---

### Step 5: コミット（Skill 自身）

全条件（テスト PASS + 品質ゲート PASS + レビュー指摘なし）を達成したら、変更をコミットする。

```bash
cd ${REPO_ROOT}
git add -A
git commit -m "<適切なコミットメッセージ>"
```

コミットメッセージは変更内容を要約し、Issue 番号を含める（例: `feat(#42): add habit streak calculation`）。

### 完了報告

コミット完了後、変更サマリーをユーザーに報告して終了する。

> **禁止事項**: Issue クローズ（`gh issue close`）、マージ（`git merge`）、プッシュ（`git push`）は Skill の範囲外である。これらはユーザーが手動で行う。Skill がこれらの操作を実行してはならない。

## エラーハンドリング

### エージェントが想定外のエラーで停止した場合

エージェントが正常な報告以外の理由で停止した場合（構文エラー、ツール失敗等）。
Skill は以下を行う:

1. エラー内容をユーザーに報告
2. AskUserQuestion で次のアクションを確認:
   - 手動で修正してからループを再開
   - Plan を修正して再実行（Step 2 に戻る）
   - Issue にコメントを残して中断
