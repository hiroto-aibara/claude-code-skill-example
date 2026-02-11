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
   - typescript-eslint, eslint-config-prettier, prettier（共通）
   - デザインシステムパッケージ（選択時）
        ↓
4. TypeScript 設定
   - tsconfig.json に strict + noUnusedLocals + noUnusedParameters
        ↓
5. ESLint 設定
   - typescript-eslint の recommendedTypeChecked を extends
   - 型安全ルール有効化（any禁止, await忘れ検出, Promise誤用検出）
   - Next.js 推奨ルール統合
   - eslint-config-prettier で整形ルール無効化
        ↓
6. Prettier 設定
   - .prettierrc 作成
   - package.json に format スクリプト追加
        ↓
7. mise.toml 更新
   - Node ツール追加（未設定の場合）
   - フロントエンドタスク追加（dev, build, lint, fmt）
        ↓
8. Pre-commit hook 更新
   - lint-staged に TS/TSX 設定追加
        ↓
9. dependabot 更新
   - npm エコシステム追加
        ↓
10. CLAUDE.md 更新
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

### TypeScript (tsconfig.json)

```json
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

※ Next.js が生成する tsconfig をベースに上記を追加。

### ESLint (eslint.config.mjs)

`typescript-eslint` の型チェック統合 + Next.js 推奨ルール + 型安全ルールを有効化する。

```javascript
import { dirname } from 'path'
import { fileURLToPath } from 'url'
import { FlatCompat } from '@eslint/eslintrc'
import tseslint from 'typescript-eslint'
import prettier from 'eslint-config-prettier'

const __dirname = dirname(fileURLToPath(import.meta.url))
const compat = new FlatCompat({ baseDirectory: __dirname })

export default tseslint.config(
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      ...tseslint.configs.recommendedTypeChecked,
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: __dirname,
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-unused-vars': ['error', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
    },
  },
  prettier,
)
```

| ルール | 効果 |
|--------|------|
| `no-explicit-any` | `any` 型の明示的な使用を禁止 |
| `no-floating-promises` | `await` 忘れを検出 |
| `no-misused-promises` | Promise を誤った場所に渡すのを検出 |
| `await-thenable` | Promise でないものを `await` するのを検出 |
| `no-unused-vars` | 未使用変数を検出（`_` 始まりは許可） |

`recommendedTypeChecked` を extends しているため、上記に加えて `no-unsafe-return`, `no-unsafe-assignment` 等の型安全ルールも自動で有効になる。

**必要パッケージ**: `typescript-eslint`, `@eslint/eslintrc`, `eslint-config-prettier`, `prettier`

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
