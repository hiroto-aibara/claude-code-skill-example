---
name: launch-workers
description: Open Issue から最大 4 件を選定し、worktree 上で tmux 並列ワーカーを起動する。
allowed-tools: Bash(gh:*), Bash(git:*), Bash(tmux:*), Bash(docker:*), Bash(bash:*), Bash(ls:*), Bash(cd:*), Bash(mise:*), Bash(go:*), Bash(npm:*), Read, Glob, AskUserQuestion
user-invocable: true
---

# Launch Workers

Open Issue を選定し、既存 worktree 上に tmux で並列ワーカー Claude Code セッションを起動する。

## 使用方法

```
/launch-workers              # 対話的に Issue 選定 → 起動
/launch-workers #41 #54      # 指定 Issue で直接起動
```

## 前提条件

- **worktree は既に存在すること**。ない場合はユーザーに通知して終了する。
- worktree の作成（`scripts/worktree-create.sh`）は Skill の範囲外。

## 実行フロー

```
Step 0: 環境検証
  ↓
  ├─ 引数あり → Step 1a: 指定 Issue バリデーション → Step 3 へ
  │
  └─ 引数なし → Step 1b: Open Issue 取得・分類
                  ↓
                Step 2: ユーザーと対象 Issue を合意
                  ↓
Step 3: worktree 同期 + tmux クリーンアップ
  ↓
Step 4: tmux ワーカー起動 + レポート
```

---

## Step 0: 環境検証

以下を順に検証する。いずれか失敗したらエラーメッセージを表示して終了。

### 0.1: worktree 内から実行されていないこと

```bash
if [[ "$PWD" =~ worktrees/ ]]; then
  echo "ERROR: worktree 内からは実行できません。メインのプロジェクトルートから実行してください。"
  # → 終了
fi
```

### 0.2: tmux / claude CLI が利用可能

```bash
which tmux && which claude
```

いずれかが見つからない場合はエラーメッセージを表示して終了。

### 0.3: 既存 worktree の検出

`worktrees/` 配下のディレクトリを列挙する。

```bash
ls -d /workspace/worktrees/wt* 2>/dev/null
```

**worktree が 0 件の場合**: 以下を表示して終了。

```
エラー: 利用可能な worktree が見つかりません。
先に worktree を作成してください:
  bash scripts/worktree-create.sh wt1
```

検出結果をまとめて表示する:

```
利用可能な worktree: wt1, wt2, wt3
```

---

## Step 1a: 指定 Issue バリデーション（引数ありの場合）

**引数で Issue 番号が指定されている場合、Step 1b・Step 2 をスキップしてこのステップのみ実行する。**

### バリデーション

各指定 Issue に対して以下を確認する:

```bash
gh issue view <番号> --json number,title,state,body,labels
```

| チェック | 失敗時の動作 |
|---------|------------|
| Issue が存在する | エラー表示して終了 |
| state が OPEN である | エラー表示して終了 |
| 件数が利用可能 worktree 数以内 | エラー表示して終了（「利用可能 worktree: N 台に対し、指定 Issue: M 件」） |
| PARENT Issue でないか | 警告を表示するが続行する（ユーザーが意図的に指定した可能性があるため） |

全件バリデーション OK → **Step 3 へ直接進む**。

---

## Step 1b: Open Issue 取得・分類（引数なしの場合）

**引数なしの場合のみ実行する。**

`gh issue list --state open` で全 Open Issue を取得し、以下のように分類する。

```bash
gh issue list --state open --json number,title,body,labels --limit 100
```

### 分類ルール

| 分類 | 条件 |
|------|------|
| **PARENT** | Issue 本文に「## サブ Issue」セクションがあり、未クローズのサブ Issue が存在する |
| **ACTIONABLE** | 上記に該当しない Open Issue |
| **CLOSEABLE** | 親 Issue だが全サブ Issue がクローズ済み（ユーザーにクローズ推奨を報告） |

### PARENT 判定ロジック

Issue 本文から `#数字` 形式のサブ Issue リンクを抽出し、それぞれの状態を確認する:

```bash
# 各サブ Issue の状態を確認
gh issue view <sub_issue_number> --json state --jq '.state'
```

- 全サブ Issue が CLOSED → **CLOSEABLE**
- 未クローズのサブ Issue が存在 → **PARENT**

### 表示

ACTIONABLE な Issue のみを番号順に一覧表示する:

```
## 着手可能な Issue（ACTIONABLE）

| # | タイトル | ラベル |
|---|---------|--------|
| 36 | ストリーク計算の実装 | backend |
| 37 | 習慣完了率ダッシュボード | frontend |
```

CLOSEABLE な Issue がある場合は別途報告する:

```
## クローズ推奨（全サブ Issue 完了済み）
- #30 目標構造の実装
```

**ACTIONABLE が 0 件の場合**: CLOSEABLE があればその旨を報告し、着手可能な Issue がない旨を表示して終了。

---

## Step 2: ユーザーと対象 Issue を合意（引数なしの場合のみ）

**引数ありの場合はこのステップをスキップする。**

AskUserQuestion で対象 Issue を選択する。

制約:
- **最大 4 件**
- **利用可能な worktree 数を超えない**（例: worktree 2 台なら最大 2 件）

```
AskUserQuestion:
  question: "起動する Issue を選択してください（最大 {N} 件、利用可能 worktree: {N} 台）"
  multiSelect: true
  options:
    - label: "#36 ストリーク計算..."
      description: "labels: backend"
    - label: "#37 習慣完了率..."
      description: "labels: frontend"
```

選択件数が 0 件の場合は終了。

---

## Step 3: worktree 同期 + tmux クリーンアップ

### 3.1: Issue と worktree の割り当て

選択された Issue を利用可能な worktree に順番に割り当てる。

```
割り当て:
  wt1 → #36
  wt2 → #37
```

### 3.2: 対象 worktree を同期

各対象 worktree に対して `worktree-sync.sh` を実行する:

```bash
bash scripts/worktree-sync.sh wt1 main
bash scripts/worktree-sync.sh wt2 main
```

sync が失敗した場合（リベースコンフリクト等）はユーザーに報告して中断する。
失敗した worktree を除外して続行するか、全体を中断するかを AskUserQuestion で確認する。

### 3.3: 既存 tmux セッションのクリーンアップ

```bash
tmux kill-session -t workers 2>/dev/null || true
```

---

## Step 4: tmux ワーカー起動 + レポート

### 4.1: tmux セッション作成 + ペイン分割

```bash
# セッション作成
tmux new-session -d -s workers -x 200 -y 50
```

件数に応じてペインを分割する:

```
N=1: 分割なし
+----------+
|   wt1    |
+----------+

N=2: 水平分割
+-----+-----+
| wt1 | wt2 |
+-----+-----+

N=3: 水平 + 右縦分割
+-----+-----+
|     | wt2 |
| wt1 +-----+
|     | wt3 |
+-----+-----+

N=4: 水平 + 両側縦分割
+-----+-----+
| wt1 | wt3 |
+-----+-----+
| wt2 | wt4 |
+-----+-----+
```

分割コマンド:

```bash
# N=2
tmux split-window -h -t workers:0.0

# N=3
tmux split-window -h -t workers:0.0
tmux split-window -v -t workers:0.1

# N=4
tmux split-window -h -t workers:0.0
tmux split-window -v -t workers:0.0
tmux split-window -v -t workers:0.2
```

### 4.2: 各ペインへワーカー起動

各ペインに cd + 環境変数 + claude コマンドを送信する:

```bash
tmux send-keys -t workers:0.${PANE} \
  "cd /workspace/worktrees/${WT_ID} && \
   unset CLAUDECODE && \
   DATABASE_URL=postgres://habitrecord:habitrecord@db:5432/habitrecord?sslmode=disable \
   claude --dangerously-skip-permissions '/start-implementation ${ISSUE_NUM}'" C-m
```

### 4.3: 起動完了レポート

全ペインへの送信完了後、以下のレポートを表示する:

```markdown
## ワーカー起動完了

| ペイン | worktree | Issue | タイトル |
|--------|----------|-------|---------|
| 0.0    | wt1      | #36   | ストリーク計算の実装 |
| 0.1    | wt2      | #37   | 習慣完了率ダッシュボード |

## 進捗確認コマンド

tmux capture-pane -t workers:0.0 -p -S -100   # wt1 直近100行
tmux capture-pane -t workers:0.1 -p -S -100   # wt2 直近100行

## ターミナルから直接閲覧

tmux attach -t workers
# デタッチ: Ctrl+b d
```

---

## 禁止事項

- worktree の新規作成（Skill 範囲外）
- コミット（`git commit`）、push（`git push`）、Issue クローズ（`gh issue close`）
- ワーカーの完了待ち（起動して報告で終了）

## 利用する既存リソース

| ファイル | 用途 |
|---------|------|
| `scripts/worktree-sync.sh` | 既存 worktree の同期 |
| `.claude/skills/start-implementation/SKILL.md` | 各ワーカーが実行するスキル |
