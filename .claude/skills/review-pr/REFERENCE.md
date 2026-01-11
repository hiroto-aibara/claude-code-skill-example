# PR Reviewer - Reference

## コマンド実行手順

### Step 1: PR情報の取得

```bash
# PR番号を変数に設定（URLからの抽出も対応）
PR_NUMBER=123

# PR基本情報取得
gh pr view $PR_NUMBER --json number,title,body,author,baseRefName,headRefName,files,additions,deletions,changedFiles

# PR diff取得
gh pr diff $PR_NUMBER

# 変更ファイル一覧
gh pr view $PR_NUMBER --json files -q '.files[].path'
```

### Step 2: 詳細分析（必要に応じて）

```bash
# 特定ファイルの完全な内容を確認（コンテキスト理解のため）
gh pr view $PR_NUMBER --json files -q '.files[].path' | while read file; do
  echo "=== $file ==="
  gh api repos/{owner}/{repo}/contents/$file?ref=<head-branch> | jq -r '.content' | base64 -d
done

# または、ローカルでブランチをチェックアウト
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER
git diff main...pr-$PR_NUMBER
```

### Step 3: レビュー投稿

```bash
# コメントのみ
gh pr review $PR_NUMBER --comment --body "レビュー内容"

# 承認
gh pr review $PR_NUMBER --approve --body "レビュー内容"

# 変更要求
gh pr review $PR_NUMBER --request-changes --body "レビュー内容"
```

## レビュー観点詳細

### 1. コード品質チェックリスト

#### 可読性
- [ ] 変数名・関数名は意図を明確に表現しているか
- [ ] 複雑なロジックにはコメントがあるか
- [ ] 関数は単一責任になっているか
- [ ] ネストが深すぎないか（3段階以内が望ましい）

#### 保守性
- [ ] DRY原則が守られているか（重複コードがないか）
- [ ] マジックナンバーが定数化されているか
- [ ] 適切な抽象化レベルか（過度な抽象化も問題）
- [ ] 設定値がハードコードされていないか

#### 設計
- [ ] 責務の分離ができているか
- [ ] 依存関係が適切か（循環依存がないか）
- [ ] インターフェースが明確か
- [ ] 拡張性を考慮しているか

### 2. バグ/ロジックエラーチェックリスト

#### 境界値・エッジケース
- [ ] 空配列・空文字列の処理
- [ ] null/undefined/nil のチェック
- [ ] 0や負の数の処理
- [ ] 最大値・最小値の処理

#### 非同期処理
- [ ] Promise/async-await のエラーハンドリング
- [ ] 競合状態（Race Condition）の可能性
- [ ] タイムアウト処理
- [ ] リトライロジック

#### 型安全性
- [ ] 型アサーションの妥当性
- [ ] any型の使用箇所
- [ ] 型推論が正しく機能しているか

### 3. セキュリティチェックリスト

#### インジェクション
- [ ] SQLインジェクション（プレースホルダ使用）
- [ ] XSS（出力エスケープ）
- [ ] コマンドインジェクション（シェル実行時）
- [ ] パストラバーサル

#### 認証・認可
- [ ] 認証チェックの漏れ
- [ ] 認可チェックの漏れ（権限確認）
- [ ] セッション管理の問題
- [ ] CSRF対策

#### 機密情報
- [ ] APIキー・トークンのハードコード
- [ ] パスワードの平文保存
- [ ] ログへの機密情報出力
- [ ] エラーメッセージでの情報漏洩

#### 依存関係
- [ ] 既知の脆弱性を持つライブラリ
- [ ] バージョン固定の有無

### 4. パフォーマンスチェックリスト

#### データベース
- [ ] N+1クエリ問題
- [ ] 不要なカラムの取得（SELECT *）
- [ ] インデックスの活用
- [ ] 大量データの一括処理

#### アルゴリズム
- [ ] 計算量が適切か（O(n²)以上に注意）
- [ ] 不要なループ・再計算
- [ ] メモ化・キャッシュの活用

#### メモリ
- [ ] メモリリークの可能性
- [ ] 大きなオブジェクトの保持
- [ ] ストリーム処理の活用

## レビューコメントのテンプレート

### Critical（修正必須）

```markdown
🔴 **Critical: [問題のタイトル]**

**場所**: `ファイル名:行番号`

**問題**:
[問題の詳細説明]

**リスク**:
[このまま放置した場合のリスク]

**修正案**:
```suggestion
修正後のコード
```
```

### Warning（要検討）

```markdown
🟡 **Warning: [問題のタイトル]**

**場所**: `ファイル名:行番号`

**懸念点**:
[懸念の詳細]

**提案**:
[改善案]
```

### Suggestion（提案）

```markdown
🔵 **Suggestion: [提案のタイトル]**

**場所**: `ファイル名:行番号`

**現状**:
[現在の実装]

**提案**:
[より良い実装案]

**理由**:
[なぜこの変更が望ましいか]
```

## レビュー結果フォーマット

```markdown
## PR Review: #[番号] - [タイトル]

### 📋 概要

| 項目 | 内容 |
|------|------|
| 変更ファイル数 | X files |
| 追加行数 | +XXX |
| 削除行数 | -XXX |
| ベースブランチ | main |

**変更の概要**: [1-2文で変更内容を要約]

---

### 🔍 レビュー結果

#### 🔴 Critical（修正必須）

[問題がない場合]
なし

[問題がある場合]
1. **[問題タイトル]** - `ファイル:行`
   - 詳細説明
   - 修正案

#### 🟡 Warning（要検討）

[問題がない場合]
なし

[問題がある場合]
1. **[問題タイトル]** - `ファイル:行`
   - 詳細説明

#### 🔵 Suggestion（提案）

[提案がない場合]
特になし

[提案がある場合]
1. **[提案タイトル]** - `ファイル:行`
   - 詳細説明

---

### ✅ 良い点

- [評価点1]
- [評価点2]

---

### 📊 総合評価

**推奨アクション**: [Approve / Request Changes / Comment]

**理由**: [推奨理由を1-2文で]

---

*このレビューはClaude Codeによる自動分析です。最終判断はレビュアーが行ってください。*
```

## アクション選択の基準

### Approve（承認）を推奨する場合
- Critical問題がない
- Warning問題も軽微または許容範囲
- 全体的にコード品質が良い

### Request Changes（変更要求）を推奨する場合
- Critical問題が1つ以上ある
- セキュリティ上の重大な懸念がある
- このままマージすると問題が発生する可能性が高い

### Comment（コメントのみ）を推奨する場合
- Criticalはないが、Warningが複数ある
- 判断に迷う点がある
- 追加の議論が必要

## Request Changes 時の投稿オプション

Request Changesを選択した後、投稿方法を選択します。

### 選択肢1: 通常のRequest Changes

レビューコメントのみを投稿します。

```bash
gh pr review $PR_NUMBER --request-changes --body "レビュー内容"
```

修正作業はこのスキルの責務外です。PR作成者またはレビュアーが別途対応します。

### 選択肢2: @claude 付きRequest Changes

GitHub Actionで自動修正させる場合、レビューコメントに `@claude` メンションを含めて投稿します。

```markdown
@claude 以下の修正をお願いします:
- [ ] エラーハンドリングを追加
- [ ] バリデーションを強化
- [ ] テストを追加
```

**前提条件**: Claude Code GitHub Actionがリポジトリに設定済みであること

## トラブルシューティング

### Q: gh コマンドで認証エラー

```bash
# 認証状態確認
gh auth status

# 再認証
gh auth login
```

### Q: PRにアクセスできない

```bash
# リポジトリ確認
gh repo view

# 組織のSSO認証が必要な場合
gh auth login --scopes 'read:org'
```

### Q: diffが大きすぎる

```bash
# ファイル単位で確認
gh pr view $PR_NUMBER --json files -q '.files[].path'

# 特定ファイルのみ
gh pr diff $PR_NUMBER -- path/to/file.ts
```

### Q: レビュー投稿に失敗

```bash
# 権限確認（Writeアクセスが必要）
gh api repos/{owner}/{repo}/collaborators/{username}/permission

# トークンのスコープ確認
gh auth status
```

## ベストプラクティス

### 1. 建設的なフィードバック
- 問題点だけでなく良い点も指摘する
- 「なぜ」を説明する
- 具体的な改善案を提示する

### 2. 優先順位をつける
- Critical → Warning → Suggestion の順で整理
- 重要な問題を見落とさない

### 3. コンテキストを考慮
- PRの目的を理解する
- 緊急度やリリーススケジュールを考慮
- 既存コードベースとの整合性

### 4. 適切な粒度
- 細かすぎず、大きすぎず
- 1つのPRで解決できる範囲の指摘
- 別PRで対応すべきものは分ける

## 関連ドキュメント

- [SKILL.md](SKILL.md) - 基本的な使い方
- [GitHub CLI Documentation](https://cli.github.com/manual/) - gh コマンドリファレンス
- [GitHub Pull Request Reviews](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests) - PRレビュー公式ドキュメント
