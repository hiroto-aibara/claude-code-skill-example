---
name: create-product-concept
description: Creates a Product Concept document defining the vision, target users, core value, MVP scope, user flow, and tech stack for a new product. Use this at the very beginning of a new product development.
allowed-tools: Write, Read, Bash(mkdir:*), AskUserQuestion
---

# Product Concept Creator

ユーザーとの対話を通じて、新規プロダクトのコンセプトドキュメントを生成します。

## 概要

このSkillは以下を実行します：

1. ユーザーからプロダクトの構想・課題・ターゲットを聞き取る
2. プロダクト概要・ターゲット・コアバリュー・MVPスコープ・ユーザーフロー・技術スタックを整理
3. `docs/product-concept.md` として保存

## 使用方法

```bash
/create-product-concept
```

### 例

```bash
/create-product-concept
# ユーザー: "習慣記録アプリを作りたい。毎日の習慣をシンプルに記録・可視化できるもの"
# → docs/product-concept.md が生成される
```

## Product Concept の位置づけ

このスキルは新規プロダクト立ち上げ時に使用します。
既存プロダクトへの機能追加には `/create-feature-brief` を使用してください。

```
Product Concept（なぜ・誰に・何を） ← このスキルで作成
    ↓
初期実装 / Feature Brief へ分解
```

## 実行手順

1. **ヒアリング**
   - プロダクトのアイデア・動機を確認
   - ターゲットユーザーと課題を確認
   - 実現したいコア体験を確認
   - 技術的な制約や希望があれば確認
   - 不明点があれば質問

2. **Product Concept 生成**
   - [TEMPLATE.md](TEMPLATE.md) のフォーマットに従って生成
   - MVPスコープは「やること/やらないこと」を明確に線引き
   - ユーザーフローは主要な流れを箇条書きで簡潔に
   - 技術スタックは選定理由も簡潔に添える

3. **ユーザーレビュー**
   - 生成したドキュメントを表示
   - 修正リクエストがあれば反映

## 生成ファイル

```
docs/
└── product-concept.md
```

## テンプレート

[TEMPLATE.md](TEMPLATE.md) にフォーマットがあります。

## 関連スキル

- `/create-feature-brief` - Feature Brief 作成（既存プロダクトへの機能追加時）
- `/create-design-doc` - Design Doc 作成（個別機能の設計時）
