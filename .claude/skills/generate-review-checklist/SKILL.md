---
name: generate-review-checklist
description: プロジェクトの規約・アーキテクチャ・コードベースを分析し、最適化されたコードレビューチェックリストを生成・更新する。
allowed-tools: Read, Grep, Glob, Write, Bash(git:*), Bash(ls:*)
user-invocable: true
---

# Generate Review Checklist

プロジェクトの規約・アーキテクチャを分析し、最適化された `REVIEW_CHECKLIST.md` を生成します。

## 概要

```
1. プロジェクト情報の収集
   - 開発規約、テスト方針、エラーハンドリング規約を読み込み
   - CLAUDE.md のプロジェクト制約を読み込み
   - 既存の REVIEW_CHECKLIST.md を読み込み（あれば）
        ↓
2. コードベースのパターン分析
   - ディレクトリ構成からレイヤ構造を把握
   - 使用フレームワーク・ライブラリの特定
   - テストの命名規則・構成の確認
   - 既存のエラーハンドリングパターン把握
        ↓
3. チェックリスト生成
   - Must / Should / Nice の3段階で分類
   - 各項目に根拠（どのドキュメント・規約に基づくか）を付記
   - プロジェクト固有の項目を優先配置
        ↓
4. ファイル出力
   - .claude/skills/shared/REVIEW_CHECKLIST.md に書き込み
```

## 使用方法

```
/generate-review-checklist
```

## フロー詳細

### 1. プロジェクト情報の収集

以下のドキュメントを読み込む（存在するもののみ）:

| ファイル | 用途 |
|---------|------|
| `CLAUDE.md` | プロジェクト全体の制約・方針 |
| `docs/dev-rules.md` | 開発規約 |
| `docs/testing-guide.md` | テスト方針・命名規則 |
| `docs/error-handling-guide.md` | エラーハンドリング規約 |
| `docs/docker-agent-teams-guide.md` | Agent Teams ガイド |
| `.claude/skills/shared/REVIEW_CHECKLIST.md` | 既存チェックリスト |

### 2. コードベースのパターン分析

#### ディレクトリ構成

```bash
# バックエンドのレイヤ構造
ls apps/api/app/

# フロントエンドの構成
ls apps/web/src/

# テスト構成
ls apps/api/tests/
```

#### 使用技術の特定

```bash
# Python 依存関係
cat apps/api/pyproject.toml

# Node.js 依存関係
cat apps/web/package.json
```

#### 既存パターンの分析

- 例外クラスの定義場所と命名規則
- テストファイルの命名パターン
- Import パターン（レイヤ間の依存方向）

### 3. チェックリスト生成

#### 分類基準

| 分類 | 基準 |
|------|------|
| **Must** | 違反するとバグ・セキュリティ問題・アーキテクチャ崩壊を引き起こす |
| **Should** | 品質・保守性に影響するが致命的ではない |
| **Nice** | さらに改善できるが対応は任意 |

#### 構成

チェックリストは以下のカテゴリで構成する:

1. **アーキテクチャ / レイヤ構造** — プロジェクト固有のレイヤルール
2. **エラーハンドリング** — 例外の使い分け・エラーコード
3. **セキュリティ** — 認証情報・Webhook署名・入力検証
4. **テスト** — 命名規則・Fixture規則・カバレッジ
5. **パフォーマンス** — N+1・不要ループ
6. **可読性・保守性** — 命名・責務分離
7. **インフラ/AWS 制約** — Lambda タイムアウト・冪等性
8. **ドキュメント** — 破壊的変更時の更新
9. **Git / コミット** — コミットメッセージ・無関係な変更

#### 各項目のフォーマット

```markdown
- [ ] **チェック項目の説明**
  - 違反例: <具体的なコード例>
  - 正解: <正しいコード例>
  - 根拠: <どのドキュメント/規約に基づくか>
```

### 4. ファイル出力

生成したチェックリストを以下に書き込む:

```
.claude/skills/shared/REVIEW_CHECKLIST.md
```

**既存ファイルがある場合**: 上書きする（バージョン管理されているため復元可能）。

出力前にユーザーにプレビューを表示し、確認を取る。

## 再生成のタイミング

以下のタイミングで再実行を推奨:

- `docs/dev-rules.md` を更新した後
- 新しいレイヤやモジュールを追加した後
- テスト方針やエラーハンドリング規約を変更した後
- 依存ライブラリの大幅な追加・変更時

## 参考

- [.claude/skills/shared/REVIEW_CHECKLIST.md](../shared/REVIEW_CHECKLIST.md) - 生成先
