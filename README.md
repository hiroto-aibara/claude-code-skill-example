# Claude Code Skill Example

Claude Codeでプランモードから開発を設計し、TASK.mdを作成してからworktreeで並列開発するためのスキルセットです。

## スキル一覧

| スキル | 説明 |
|--------|------|
| [create-task](./.claude/skills/create-task/SKILL.md) | ユーザーの説明を元にTASK.mdを生成 |
| [create-multiple-worktrees](./.claude/skills/create-multiple-worktrees/SKILL.md) | TASK.mdから複数のworktreeを一括作成 |
| [create-worktree](./.claude/skills/create-worktree/SKILL.md) | 単一のworktreeを作成 |
| [create-pr](./.claude/skills/create-pr/SKILL.md) | PR作成 |
| [cleanup-worktree](./.claude/skills/cleanup-worktree/SKILL.md) | worktree削除（PRマージ後に使用） |
| [review-pr](./.claude/skills/review-pr/SKILL.md) | GitHub PRをレビューしてコメント投稿 |

## ワークフロー

### 役割

| 役割 | 責務 |
|------|------|
| **オーケストレーター** | 設計・タスク分割・worktree作成・レビュー・クリーンアップ |
| **実装者** | worktree内での開発・PR作成 |

### フロー図

```mermaid
flowchart TD
    subgraph Orchestrator["オーケストレーター"]
        A["/plan で全体設計"]
        B["/create-task でTASK.md作成"]
        C["/create-multiple-worktrees でworktree一括作成"]
        A --> B --> C
    end

    subgraph Implementer["実装者（各worktreeで並列作業）"]
        D["cd .worktrees/&lt;feature&gt; && claude"]
        E["開発・コミット"]
        F["/create-pr でPR作成"]
        D --> E --> F
    end

    subgraph Review["オーケストレーター"]
        G["/review-pr でレビュー"]
        H{"Approve?"}
        I["マージ"]
        G --> H
        H -->|Yes| I
    end

    subgraph Fix["実装者"]
        J["修正・コミット・プッシュ"]
    end

    subgraph Cleanup["オーケストレーター"]
        K["/cleanup-worktree でworktree削除"]
    end

    C --> D
    F --> G
    H -->|No| J
    J --> G
    I --> K
```

## 使い方

### オーケストレーター

#### 1. TASK.md作成

```bash
/create-task user-auth
# → ユーザーがタスク内容を説明
# → Claude Codeが要件・品質基準を含むTASK.mdを生成
# → tasks/user-auth.md として保存
```

#### 2. Worktree一括作成

```bash
/create-multiple-worktrees tasks/*.md
# または
/create-multiple-worktrees tasks/user-auth.md tasks/dashboard.md
```

#### 3. PRレビュー

```bash
# PR番号で指定
/review-pr 123

# URL形式でも可
/review-pr https://github.com/owner/repo/pull/123
```

レビュー後、Approve / Request Changes / Comment を選択してGitHubに投稿します。

#### 4. worktree削除（PRマージ後）

```bash
/cleanup-worktree
```

---

### 実装者

#### 1. worktreeで開発

```bash
cd .worktrees/user-auth && claude
```

#### 2. PR作成

```bash
/create-pr
```

## 他プロジェクトへの導入

### ディレクトリ構成

```
.claude/
├── skill-source/          ← submodule（このリポジトリ）
│   └── .claude/skills/
│       ├── create-pr/
│       ├── review-pr/
│       └── ...
└── skills/                ← 実際に使用するスキル（コミット対象）
    ├── create-pr/         ← skill-sourceからコピー
    ├── review-pr/         ← skill-sourceからコピー
    └── my-custom-skill/   ← プロジェクト固有のスキル
```

### 1. Submoduleとして追加

```bash
# skillsとして認識されない場所に配置
git submodule add https://github.com/boost-consulting/claude-code-skill-example-aibara .claude/skill-source
```

### 2. 必要なスキルをコピー

```bash
# 使いたいスキルを .claude/skills/ にコピー
cp -r .claude/skill-source/.claude/skills/create-pr .claude/skills/

# コミット
git add .claude/skills/
git commit -m "add create-pr skill"
```

**ポイント:**
- `.claude/skill-source/` はスキルとして認識されない
- 使いたいスキルだけを `.claude/skills/` にコピー
- プロジェクト固有のスキルは `.claude/skills/` に直接配置可能

---

## スキル改善のフィードバック（PR手順）

他プロジェクトでスキルを改善した場合のPR手順。

### 1. skill-source内で編集・コミット

```bash
cd .claude/skill-source
git checkout -b improve/create-pr-enhancement

# ファイルを編集...

git add .
git commit -m "feat(create-pr): add support for draft PR"
```

### 2. PRを作成

```bash
git push origin improve/create-pr-enhancement
# GitHub上でPRを作成
```

### 3. マージ後、プロジェクトに同期

```bash
cd .claude/skill-source
git checkout main && git pull
cd ../..

# 更新されたスキルをコピー
cp -r .claude/skill-source/.claude/skills/create-pr .claude/skills/

git add .claude/skills/ .claude/skill-source
git commit -m "sync: update create-pr skill"
```

---

## リファレンス

このリポジトリは以下を元に作成されています：

- [shikajiro/claude-code-skill-example](https://github.com/shikajiro/claude-code-skill-example/tree/main)
