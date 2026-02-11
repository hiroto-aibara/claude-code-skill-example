---
name: init-react-frontend
description: Set up React frontend with Vite, TypeScript, ESLint, Prettier, and dev proxy. Run after init-project.
allowed-tools: Bash, Write, Read, Edit
---

# Init React Frontend

React フロントエンドのセットアップを行います。

## 概要

このスキルは以下を実行します：

```
1. 情報収集（対話）
   - 追加パッケージ（例: @dnd-kit, react-router, zustand）
   - API proxy 先ポート（デフォルト: 8080）
   - ディレクトリ名（デフォルト: web）
        ↓
2. Vite プロジェクト初期化
   - npm create vite -- --template react-ts
   - npm install
        ↓
3. 追加パッケージインストール
   - ユーザー指定パッケージ
   - typescript-eslint, eslint-config-prettier, prettier（共通）
        ↓
4. TypeScript 設定
   - tsconfig.json に strict + noUnusedLocals + noUnusedParameters
        ↓
5. ESLint 設定
   - typescript-eslint の recommendedTypeChecked を extends
   - 型安全ルール有効化（any禁止, await忘れ検出, Promise誤用検出）
   - React Hooks ルール有効化
   - eslint-config-prettier で整形ルール無効化
        ↓
6. Prettier 設定
   - .prettierrc 作成
        ↓
7. Vite 設定更新
   - API proxy 設定（/api → バックエンド）
   - WebSocket proxy 設定（/ws → バックエンド）
        ↓
8. mise.toml 更新
   - Node ツール追加
   - フロントエンドタスク追加（dev:front, fmt, lint）
        ↓
9. Pre-commit hook 更新
   - lint-staged に TS/TSX 設定追加（prettier + eslint）
        ↓
10. dependabot 更新
    - npm エコシステム追加
        ↓
11. CLAUDE.md 更新
    - フロントエンドコマンド追記
```

## 使用方法

```bash
/init-react-frontend
```

## 作成・更新されるファイル

### 新規作成

```
web/
├── index.html
├── package.json
├── package-lock.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── vite.config.ts
├── eslint.config.js
├── .prettierrc
├── public/
└── src/
    ├── App.tsx
    ├── main.tsx
    ├── App.css
    └── index.css
```

### 更新

```
├── mise.toml               (Node + フロントタスク追加)
├── package.json            (lint-staged TS 設定追加)
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
  "trailingComma": "all"
}
```

### ESLint (eslint.config.mjs)

`typescript-eslint` の型チェック統合 + 型安全ルールを有効化する。

```javascript
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import prettier from 'eslint-config-prettier'

export default tseslint.config(
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      ...tseslint.configs.recommendedTypeChecked,
    ],
    plugins: {
      'react-hooks': reactHooks,
    },
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
        ecmaFeatures: { jsx: true },
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
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
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
| `react-hooks/*` | Hooks ルール違反を検出 |

`recommendedTypeChecked` を extends しているため、上記に加えて `no-unsafe-return`, `no-unsafe-assignment` 等の型安全ルールも自動で有効になる。

**必要パッケージ**: `typescript-eslint`, `eslint`, `eslint-plugin-react-hooks`, `eslint-config-prettier`, `prettier`

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

### Vite Dev Proxy

```typescript
server: {
  proxy: {
    '/api': 'http://localhost:<port>',
    '/ws': { target: 'http://localhost:<port>', ws: true }
  }
}
```

## 前提条件

- `init-project` が実行済み
- `mise` がインストール済み（Node は mise 経由でインストール）

## カスタマイズ

### よく使う追加パッケージ

| パッケージ | 用途 |
|-----------|------|
| `@dnd-kit/core @dnd-kit/sortable` | ドラッグ&ドロップ |
| `react-router-dom` | ルーティング |
| `zustand` | 状態管理 |
| `@tanstack/react-query` | サーバー状態管理 |
| `clsx` | クラス名結合 |

対話時に指定すると自動インストール。

### CSS方式

デフォルトは CSS Modules（Vite 標準対応）。
以下も対話時に選択可能：

- **Tailwind CSS**: `tailwindcss` + PostCSS 設定追加
- **CSS-in-JS**: `styled-components` 等
- **Plain CSS**: そのまま

## 関連スキル

- `init-project`: プロジェクト基盤（先に実行）
- `init-go-backend`: バックエンドセットアップ
