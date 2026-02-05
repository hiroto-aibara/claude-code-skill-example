---
name: init-nextjs-frontend
description: Set up Next.js frontend with App Router, TypeScript, ESLint, Prettier. Run after init-project.
allowed-tools: Bash, Write, Read, Edit, AskUserQuestion
---

# Init Next.js Frontend

Next.js (App Router) フロントエンドのセットアップを行います。

## 概要

このスキルは以下を実行します：

```
1. 情報収集（対話）
   - ディレクトリ名（デフォルト: dashboard）
   - 追加パッケージ（例: zustand, @tanstack/react-query）
   - デザインシステム使用有無
   - CSS方式（Tailwind / CSS Modules / デザインシステム）
        ↓
2. Next.js プロジェクト初期化
   - npx create-next-app@latest --typescript --app --eslint
   - 不要ファイルの削除・整理
        ↓
3. 追加パッケージインストール
   - ユーザー指定パッケージ
   - prettier, eslint-config-prettier（共通）
   - デザインシステムパッケージ（選択時）
        ↓
4. ESLint 設定
   - eslint-config-prettier 統合
   - Next.js 推奨ルール
        ↓
5. Prettier 設定
   - .prettierrc 作成
   - package.json に format スクリプト追加
        ↓
6. mise.toml 更新
   - Node ツール追加（未設定の場合）
   - フロントエンドタスク追加（dev, build, lint, fmt）
        ↓
7. Pre-commit hook 更新
   - lint-staged に TS/TSX 設定追加
        ↓
8. dependabot 更新
   - npm エコシステム追加
        ↓
9. CLAUDE.md 更新
   - フロントエンドコマンド追記
```

## 使用方法

```bash
/init-nextjs-frontend
```

## 対話での質問

### 1. ディレクトリ名

```
Next.js プロジェクトのディレクトリ名を指定してください。
デフォルト: dashboard
```

### 2. 追加パッケージ

```
追加でインストールするパッケージを指定してください（スペース区切り）。
例: zustand @tanstack/react-query clsx

よく使うパッケージ:
- zustand: 状態管理
- @tanstack/react-query: サーバー状態管理
- clsx: クラス名結合
- date-fns: 日付処理
- zod: バリデーション
```

### 3. デザインシステム

```
デザインシステムを使用しますか？

1. 使用する（@ds/tokens, @ds/ui, @ds/icons をインストール）
2. 使用しない
```

デザインシステム使用時のインストールコマンド:
```bash
pnpm add github:hiroto-aibara/design-system#main&path:packages/tokens
pnpm add github:hiroto-aibara/design-system#main&path:packages/ui
pnpm add github:hiroto-aibara/design-system#main&path:packages/icons
```

### 4. CSS方式

```
CSS方式を選択してください:

1. デザインシステム（@ds/tokens + CSS変数）※DS使用時推奨
2. Tailwind CSS
3. CSS Modules（Next.js標準）
4. Plain CSS
```

## 作成・更新されるファイル

### 新規作成

```
{directory}/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── components/
│   │   └── .gitkeep
│   └── lib/
│       └── .gitkeep
├── public/
├── package.json
├── tsconfig.json
├── next.config.ts
├── eslint.config.mjs
└── .prettierrc
```

### 更新

```
├── mise.toml               (Node + フロントタスク追加)
├── package.json            (lint-staged 設定追加) ※ルート
├── .github/dependabot.yml  (npm 追加)
└── CLAUDE.md               (フロントコマンド追記)
```

## 設定内容

### Prettier (.prettierrc)

```json
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "all",
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

※ Tailwind 未使用時は plugins を除外

### ESLint (eslint.config.mjs)

```javascript
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";
import prettier from "eslint-config-prettier";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  prettier,
];

export default eslintConfig;
```

### TypeScript (tsconfig.json)

Next.js デフォルト + strict モード:
- `strict: true`
- `noUnusedLocals: true`
- `noUnusedParameters: true`

### Next.js 設定 (next.config.ts)

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // 必要に応じて設定追加
};

export default nextConfig;
```

## mise.toml への追記内容

```toml
[tools]
node = "22"

[tasks.dev]
description = "Start Next.js development server"
run = "cd {directory} && npm run dev"

[tasks.build]
description = "Build Next.js for production"
run = "cd {directory} && npm run build"

[tasks.lint]
description = "Run ESLint"
run = "cd {directory} && npm run lint"

[tasks.fmt]
description = "Format code with Prettier"
run = "cd {directory} && npm run format"
```

## dependabot.yml への追記内容

```yaml
- package-ecosystem: "npm"
  directory: "/{directory}"
  schedule:
    interval: "weekly"
```

## 前提条件

- `init-project` が実行済み
- `mise` がインストール済み
- `node` が mise 経由でインストール可能

## 実行例

```bash
# スキル実行
/init-nextjs-frontend

# 対話
? ディレクトリ名: dashboard
? 追加パッケージ: zustand clsx
? デザインシステム: 使用する
? CSS方式: デザインシステム

# 実行結果
✓ Next.js プロジェクト作成: dashboard/
✓ 追加パッケージインストール: zustand, clsx
✓ デザインシステムインストール: @ds/tokens, @ds/ui, @ds/icons
✓ ESLint 設定完了
✓ Prettier 設定完了
✓ mise.toml 更新完了
✓ lint-staged 設定完了
✓ dependabot.yml 更新完了
✓ CLAUDE.md 更新完了

次のステップ:
  cd dashboard && npm run dev
```

## デザインシステム使用時のレイアウト例

```tsx
// src/app/layout.tsx
import '@ds/tokens'
import '@ds/ui/styles.css'
import './globals.css'

import { AppShell, GlobalNav, NavLogo, NavItem } from '@ds/ui'
import { ToastProvider } from '@ds/ui'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja" data-theme="light">
      <body>
        <ToastProvider>
          <AppShell>
            <GlobalNav>
              <NavLogo>App Name</NavLogo>
              <NavItem href="/">Home</NavItem>
            </GlobalNav>
            <main>{children}</main>
          </AppShell>
        </ToastProvider>
      </body>
    </html>
  )
}
```

## 関連スキル

- `init-project`: プロジェクト基盤（先に実行）
- `init-react-frontend`: Vite + React 版（Next.js 不要な場合）
- `init-go-backend`: バックエンドセットアップ
