# Create PR - Reference

## コマンドライン引数

| 引数 | 説明 | デフォルト |
|------|------|------------|
| `--title <title>` | PRタイトル | インタラクティブ入力 |
| `--body <body>` | PR本文 | インタラクティブ入力 |
| `--base <branch>` | ベースブランチ | main |
| `--draft` | ドラフトPRとして作成 | false |
| `--force` | 未コミット変更があっても続行 | false（非推奨） |
| `--help` | ヘルプメッセージを表示 | - |

## 内部処理フロー

### 1. 環境検証フェーズ
```bash
1. gitリポジトリ内かチェック
   - git rev-parse --git-dir
2. worktreeディレクトリ内かチェック
   - .git/worktrees/<name> を確認
3. 現在のブランチ名取得
   - git branch --show-current
4. gh CLI のインストール確認
```

### 2. 変更チェックフェーズ
```bash
1. 未コミット変更チェック
   - git status --porcelain
   - 出力が空でなければエラー
2. push状態チェック
   - git rev-list origin/<branch>..HEAD
   - unpushedコミットがあれば警告（継続可能）
```

### 3. PR作成フェーズ
```bash
1. gh pr create 実行
   - --title / --body 指定がなければインタラクティブ
   - --base でベースブランチ指定（デフォルト: main）
2. PR URL取得
   - gh pr view --json url -q .url
3. 成功確認
   - 終了コード 0 を確認
```

## 使用例

### ケース1: 基本的な使い方
```bash
cd .worktrees/feature-x
bash ../../.claude/skills/create-pr/scripts/create_pr.sh
# → PR作成（インタラクティブ）
# → worktreeは残る
```

### ケース2: タイトル・本文を事前指定
```bash
bash create_pr.sh \
  --title "feat(frontend): Add user authentication" \
  --body "Implements Firebase Auth integration"
```

### ケース3: ドラフトPR作成
```bash
bash create_pr.sh --draft
```

### ケース4: カスタムベースブランチ
```bash
# develop ブランチにPR作成
bash create_pr.sh --base develop
```

## トラブルシューティング

### Q: 未コミットの変更があると言われる
```bash
# 変更を確認
git status

# コミットする
git add .
git commit -m "commit message"

# または stash
git stash
```

### Q: gh CLI の認証が必要と言われる
```bash
# GitHub CLIの認証
gh auth login

# 認証状態確認
gh auth status
```

### Q: リモートブランチにpush済みか確認したい
```bash
# ローカルとリモートの差分確認
git rev-list origin/<branch>..HEAD --count

# 0なら差分なし
```

## 関連ドキュメント

- [SKILL.md](SKILL.md) - 基本的な使い方
- [cleanup-worktree スキル](../cleanup-worktree/SKILL.md) - worktree削除
- [GitHub CLI Documentation](https://cli.github.com/manual/) - gh コマンドリファレンス
