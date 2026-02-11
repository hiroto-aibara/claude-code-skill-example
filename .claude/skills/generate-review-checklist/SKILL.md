---
name: generate-review-checklist
description: プロジェクトの規約・アーキテクチャ・コードベースを分析し、最適化されたコードレビューチェックリストを生成・更新する。
allowed-tools: Read, Grep, Glob, Write, Bash(git:*), Bash(ls:*)
user-invocable: true
---

# Generate Review Checklist

プロジェクトの規約・アーキテクチャを分析し、**3ファイル構成**のレビューチェックリストを生成します。

## 概要

```
1. プロジェクト情報の収集
   - 開発規約、テスト方針、エラーハンドリング規約を読み込み
   - CLAUDE.md のプロジェクト制約を読み込み
   - docs/ 配下の仕様ドキュメントを読み込み
   - 既存のチェックリストファイルを読み込み（あれば）
        ↓
2. コードベースのパターン分析
   - ディレクトリ構成からレイヤ構造を把握
   - 使用フレームワーク・ライブラリの特定
   - テストの命名規則・構成の確認
   - 既存のエラーハンドリングパターン把握
        ↓
3. チェックリスト生成（3ファイル）
   - COMMON: セキュリティ、パフォーマンス、Git、ドキュメント
   - BACKEND: アーキテクチャ、エラー、テスト、ログ、DB
   - FRONTEND: ルーティング、状態管理、i18n、UX
   - Must / Should / Nice の3段階で分類
   - 各項目に根拠（どのドキュメント・規約に基づくか）を付記
   - プロジェクト固有の項目を優先配置
        ↓
4. ファイル出力（3ファイル）
   - .claude/skills/shared/REVIEW_CHECKLIST_COMMON.md
   - .claude/skills/shared/REVIEW_CHECKLIST_BACKEND.md
   - .claude/skills/shared/REVIEW_CHECKLIST_FRONTEND.md
```

## 使用方法

```
/generate-review-checklist
```

## 3ファイル構成

PR の変更対象に応じて **共通 + 該当スタック** の2ファイルを参照する設計です。

```
.claude/skills/shared/
├── REVIEW_CHECKLIST_COMMON.md     # 共通: セキュリティ、パフォーマンス、Git、ドキュメント
├── REVIEW_CHECKLIST_BACKEND.md    # バックエンド: アーキテクチャ、エラー、テスト、ログ、DB
└── REVIEW_CHECKLIST_FRONTEND.md   # フロントエンド: ルーティング、状態管理、i18n、UX
```

| PR の変更対象 | 参照するファイル |
|--------------|----------------|
| バックエンドのみ | COMMON + BACKEND |
| フロントエンドのみ | COMMON + FRONTEND |
| 両方 | COMMON + BACKEND + FRONTEND |

## フロー詳細

### 1. プロジェクト情報の収集

以下のドキュメントを読み込む（存在するもののみ）:

| ファイル | 用途 |
|---------|------|
| `CLAUDE.md` | プロジェクト全体の制約・方針 |
| `docs/dev/architecture.md` | レイヤー設計・依存方向ルール |
| `docs/dev/conventions.md` | エラーハンドリング・テスト・ログ規約 |
| `docs/spec/api.md` | API 仕様・エラーレスポンス形式 |
| `docs/spec/data-model.md` | データモデル・バリデーション・制約 |
| `docs/spec/requirements.md` | 非機能要件・セキュリティ・パフォーマンス目標 |
| `docs/spec/screen-design.md` | 画面設計・状態定義 |
| `.claude/skills/shared/REVIEW_CHECKLIST_*.md` | 既存チェックリスト |

### 2. コードベースのパターン分析

#### ディレクトリ構成

```bash
# バックエンドのレイヤ構造
ls internal/    # Go の場合
ls apps/api/    # Python の場合

# フロントエンドの構成
ls mobile/app/  # React Native の場合
ls apps/web/    # Web の場合
```

#### 使用技術の特定

```bash
# Go 依存関係
cat go.mod

# Python 依存関係
cat pyproject.toml

# Node.js 依存関係
cat package.json
```

#### 既存パターンの分析

- エラー型の定義場所と命名規則
- テストファイルの命名パターン
- Import パターン（レイヤ間の依存方向）

### 3. チェックリスト生成

#### 分類基準

| 分類 | 基準 |
|------|------|
| **Must** | 違反するとバグ・セキュリティ問題・アーキテクチャ崩壊を引き起こす |
| **Should** | 品質・保守性に影響するが致命的ではない |
| **Nice** | さらに改善できるが対応は任意 |

#### ファイルごとのカテゴリ構成

**COMMON（共通）:**
1. セキュリティ — 認証情報、SQLインジェクション、IDOR、JWT、CORS、入力検証
2. パフォーマンス — N+1、クエリ数、タイムアウト、リソースリーク
3. ドキュメント — 破壊的変更時の更新
4. Git / コミット — Conventional Commits、無関係な変更

**BACKEND（バックエンド）:**
1. アーキテクチャ / レイヤー構造 — 依存方向、DI 配線、責務分離
2. エラーハンドリング — エラー型の使い分け、レイヤー責務
3. API 仕様準拠 — レスポンス形式、日時フォーマット
4. バリデーション / データ整合性 — Validate() 呼び出し、上限チェック
5. テスト — テーブル駆動、カバレッジ目標
6. ログ — ログライブラリ、レイヤーごとのルール
7. データベース — マイグレーション、インデックス

**FRONTEND（フロントエンド）:**
1. ルーティング / ナビゲーション — 画面パス、認証ガード
2. 状態管理 / データ取得 — トークン保存、エラーハンドリング
3. 多言語対応（i18n） — ハードコード禁止
4. フォーム / バリデーション — クライアント側バリデーション
5. UX / パフォーマンス — ローディング UI、二重送信防止
6. TypeScript — any 禁止、型定義

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
.claude/skills/shared/REVIEW_CHECKLIST_COMMON.md
.claude/skills/shared/REVIEW_CHECKLIST_BACKEND.md
.claude/skills/shared/REVIEW_CHECKLIST_FRONTEND.md
```

**既存ファイルがある場合**: 上書きする（バージョン管理されているため復元可能）。

出力前にユーザーにプレビューを表示し、確認を取る。

## 再生成のタイミング

以下のタイミングで再実行を推奨:

- 開発規約ドキュメントを更新した後
- 新しいレイヤやモジュールを追加した後
- テスト方針やエラーハンドリング規約を変更した後
- 依存ライブラリの大幅な追加・変更時
- API 仕様やデータモデルを大幅に変更した後

## 参考

- [TEMPLATE.md](TEMPLATE.md) - チェックリストテンプレート（3ファイル構成）
- [.claude/skills/shared/REVIEW_CHECKLIST_COMMON.md](../shared/REVIEW_CHECKLIST_COMMON.md) - 共通チェックリスト
- [.claude/skills/shared/REVIEW_CHECKLIST_BACKEND.md](../shared/REVIEW_CHECKLIST_BACKEND.md) - バックエンドチェックリスト
- [.claude/skills/shared/REVIEW_CHECKLIST_FRONTEND.md](../shared/REVIEW_CHECKLIST_FRONTEND.md) - フロントエンドチェックリスト
