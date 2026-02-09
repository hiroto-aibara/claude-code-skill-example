---
name: cleanup-branches
description: PR マージ後のクリーンアップ。main ブランチ最新化、マージ済みブランチ・worktree の安全な削除を実行する。危険な操作はユーザー承認を必須とする。
allowed-tools: Bash(git:*), Bash(ls:*), Bash(rm:*), Read, AskUserQuestion
user-invocable: true
---

# Cleanup Branches

PR マージ後にローカル環境をクリーンアップします。

## 概要

```
1. main ブランチ最新化
   - git checkout main && git pull origin main
        ↓
2. マージ済みブランチ検出
   - git branch --merged main でマージ済みローカルブランチを抽出
   - main, develop 等の保護ブランチを除外
        ↓
3. 対応する worktree 検出
   - git worktree list でクリーンな worktree を特定
        ↓
4. 安全な削除を自動実行
   - マージ済みブランチ: git branch -d
   - クリーンな worktree: git worktree remove
        ↓
5. 結果報告
   - 削除したブランチ・worktree の一覧を表示
   - 未マージブランチがあれば通知
```

## 使用方法

```
/cleanup-branches
```

## 操作の安全性分類

### 確認不要（自動実行）

以下の操作はマージ済み・クリーンな状態であれば安全なため、確認なしで実行する:

- `git checkout main && git pull origin main` — main ブランチの最新化
- `git branch -d <branch>` — マージ済みブランチの削除（`-d` は未マージなら失敗する）
- `git worktree remove <path>` — 未コミット変更がない worktree の削除

### 確認必須

以下の操作はユーザーの明示的な承認を得てから実行する:

- `git branch -D <branch>` — 未マージブランチの強制削除
- `git push origin --delete <branch>` — リモートブランチの削除
- `git worktree remove --force <path>` — 未コミット変更がある worktree の強制削除

### 禁止（実行してはならない）

以下の操作はいかなる場合も実行しない:

- `rm -rf worktrees/` — git worktree 管理外の直接削除
- `git clean -f` — 追跡外ファイルの一括削除
- `git reset --hard` — コミット履歴の巻き戻し
- `git push --force` — リモートの強制上書き

## フロー詳細

### 1. main ブランチ最新化

```bash
git checkout main
git pull origin main
```

### 2. マージ済みブランチ検出

```bash
# マージ済みブランチを一覧（main, develop を除外）
git branch --merged main | grep -v -E '^\*|main|develop'
```

### 3. 対応する worktree 検出

```bash
# worktree 一覧
git worktree list

# 各 worktree の状態確認（未コミット変更の有無）
cd <worktree-path> && git status --porcelain
```

### 4. 安全な削除

マージ済みブランチとクリーンな worktree を一括削除:

```bash
# worktree 削除（ブランチ削除の前に実行）
git worktree remove worktrees/<name>

# マージ済みブランチ削除
git branch -d feat/<branch-name>
```

### 5. 結果報告

```markdown
## クリーンアップ完了

### 削除済み
- ブランチ: feat/101-user-auth, feat/102-onboarding-api
- Worktree: worktrees/101-user-auth, worktrees/102-onboarding-api

### 未マージ（残存）
- feat/103-docusign-webhook（未マージのため削除をスキップ）
```

未マージブランチが残っている場合は、強制削除するかどうかを AskUserQuestion で確認する:

```
未マージブランチがあります。強制削除しますか？
  ○ 強制削除する（git branch -D）
  ○ そのまま残す（推奨）
```

### リモートブランチ削除（オプション）

ローカル削除完了後、リモートブランチの削除を提案する:

```
リモートにも削除対象のブランチがあります。削除しますか？
  ○ 削除する（git push origin --delete）
  ○ スキップする
```

## 参考

- [docs/docker-agent-teams-guide.md](../../../docs/docker-agent-teams-guide.md) - Docker + Agent Teams ガイド
