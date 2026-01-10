# Multiple Worktree Creator - Reference

## 使用例

### 複数のTASK.mdからworktree作成

```bash
bash .claude/skills/create-multiple-worktrees/scripts/create_multiple_worktrees.sh \
  tasks/user-auth.md \
  tasks/dashboard.md \
  tasks/api-v2.md

# 出力例:
# [INFO] Creating 3 worktrees from TASK.md files...
# [STEP] Creating worktree: user-auth
# [INFO] TASK.md copied to .worktrees/user-auth
# [✓] user-auth created (.worktrees/user-auth)
# ...
```

### ワイルドカードで一括指定

```bash
bash .claude/skills/create-multiple-worktrees/scripts/create_multiple_worktrees.sh tasks/*.md
```

### ドライラン（事前確認）

```bash
bash .claude/skills/create-multiple-worktrees/scripts/create_multiple_worktrees.sh \
  --dry-run tasks/*.md

# 出力例:
# [DRY-RUN] Would create the following worktrees:
#   - .worktrees/user-auth/
#     ├── TASK.md (from tasks/user-auth.md)
#     ├── .env
#     └── (branch: feature/user-auth)
```

## TASK.mdファイル名とworktreeの対応

ファイル名がそのままfeature名・ブランチ名になります：

```
tasks/user-auth.md     → .worktrees/user-auth/  (branch: feature/user-auth)
tasks/fix-login.md     → .worktrees/fix-login/  (branch: feature/fix-login)
tasks/refactor-api.md  → .worktrees/refactor-api/ (branch: feature/refactor-api)
```

## トラブルシューティング

### Q: TASK.mdファイルが見つからない

```bash
ls -la tasks/
```

### Q: worktree作成に失敗した

```bash
# 状態確認
git worktree list

# 既存のworktreeを削除して再作成
git worktree remove .worktrees/<feature-name>
```

### Q: ポートが競合する

各worktreeの `.env` にはランダムなポートが割り当てられます。
手動で変更する場合：

```bash
vim .worktrees/<feature-name>/.env
```

### Q: worktreeを削除したい

```bash
# 個別に削除
git worktree remove .worktrees/<feature-name>

# 一括削除
for wt in .worktrees/*/; do git worktree remove --force "$wt"; done
git worktree prune
```

## 関連ドキュメント

- [Git Worktree公式ドキュメント](https://git-scm.com/docs/git-worktree)
