---
name: init-react-native
description: Set up React Native (Expo) mobile app with TypeScript, Expo Router, ESLint, Prettier. Run after init-project.
allowed-tools: Bash, Write, Read, Edit, AskUserQuestion
---

# Init React Native (Expo)

React Native (Expo) モバイルアプリのセットアップを行います。

## 概要

このスキルは以下を実行します：

```
1. 情報収集（対話）
   - ディレクトリ名（デフォルト: mobile）
   - 追加パッケージ（例: zustand, @tanstack/react-query）
   - API ベース URL（デフォルト: http://localhost:8080）
   - ナビゲーション方式（Expo Router ※デフォルト / React Navigation）
        ↓
2. Expo プロジェクト初期化
   - npx create-expo-app --template blank-typescript
   - 不要ファイルの削除・整理
        ↓
3. 追加パッケージインストール
   - ユーザー指定パッケージ
   - typescript-eslint, eslint-config-prettier, prettier（共通）
   - expo-router 関連（選択時）
        ↓
4. Expo Router セットアップ（選択時）
   - expo-router + 依存パッケージインストール
   - app/ ディレクトリ作成
   - エントリポイント設定
        ↓
5. TypeScript 設定
   - tsconfig.json に strict + noUnusedLocals + noUnusedParameters
        ↓
6. ESLint 設定
   - typescript-eslint の recommendedTypeChecked を extends
   - 型安全ルール有効化（any禁止, await忘れ検出, Promise誤用検出）
   - eslint-config-prettier で整形ルール無効化
        ↓
7. Prettier 設定
   - .prettierrc 作成
   - package.json に format スクリプト追加
        ↓
7. API クライアント設定
   - lib/api.ts 作成（ベース URL 設定）
        ↓
9. mise.toml 更新
   - Node ツール追加（未設定の場合）
   - モバイルタスク追加（dev:mobile, lint, fmt）
        ↓
10. Pre-commit hook 更新
   - lint-staged に TS/TSX 設定追加（prettier + eslint）
        ↓
11. dependabot 更新
    - npm エコシステム追加
        ↓
12. CLAUDE.md 更新
    - モバイルコマンド追記
```

## 使用方法

```bash
/init-react-native
```

## 対話での質問

### 1. ディレクトリ名

```
Expo プロジェクトのディレクトリ名を指定してください。
デフォルト: mobile
```

### 2. 追加パッケージ

```
追加でインストールするパッケージを指定してください（スペース区切り）。
例: zustand @tanstack/react-query clsx

よく使うパッケージ:
- zustand: 状態管理
- @tanstack/react-query: サーバー状態管理
- react-native-reanimated: アニメーション
- react-native-gesture-handler: ジェスチャー
- clsx: クラス名結合（NativeWind使用時）
- date-fns: 日付処理
- zod: バリデーション
```

### 3. API ベース URL

```
Go バックエンドの API ベース URL を指定してください。
デフォルト: http://localhost:8080
```

### 4. ナビゲーション方式

```
ナビゲーション方式を選択してください:

1. Expo Router（推奨。ファイルベースルーティング）
2. React Navigation（手動ルーティング定義）
```

### 5. スタイリング方式

```
スタイリング方式を選択してください:

1. StyleSheet（React Native 標準）
2. NativeWind（Tailwind CSS for React Native）
```

## 作成・更新されるファイル

### 新規作成

#### Expo Router 選択時

```
{directory}/
├── app/
│   ├── _layout.tsx
│   ├── index.tsx
│   └── +not-found.tsx
├── components/
│   └── .gitkeep
├── lib/
│   └── api.ts
├── constants/
│   └── .gitkeep
├── assets/
│   └── images/
├── app.json
├── package.json
├── tsconfig.json
├── eslint.config.mjs
├── .prettierrc
└── babel.config.js
```

#### React Navigation 選択時

```
{directory}/
├── src/
│   ├── screens/
│   │   └── HomeScreen.tsx
│   ├── navigation/
│   │   └── RootNavigator.tsx
│   ├── components/
│   │   └── .gitkeep
│   ├── lib/
│   │   └── api.ts
│   └── constants/
│       └── .gitkeep
├── App.tsx
├── assets/
│   └── images/
├── app.json
├── package.json
├── tsconfig.json
├── eslint.config.mjs
├── .prettierrc
└── babel.config.js
```

### 更新

```
├── mise.toml               (Node + モバイルタスク追加)
├── package.json            (lint-staged TS/TSX 設定追加) ※ルート
├── .github/dependabot.yml  (npm 追加)
└── CLAUDE.md               (モバイルコマンド追記)
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

### TypeScript (tsconfig.json)

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

| オプション | 効果 |
|-----------|------|
| `strict` | `noImplicitAny` 等の厳密チェックを一括有効化 |
| `noUnusedLocals` | 使っていない変数を検出 |
| `noUnusedParameters` | 使っていない関数引数を検出 |

### ESLint (eslint.config.mjs)

`typescript-eslint` の型チェック統合 + 型安全ルールを有効化する。

```javascript
import tseslint from 'typescript-eslint'
import prettier from 'eslint-config-prettier'

export default tseslint.config(
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      ...tseslint.configs.recommendedTypeChecked,
    ],
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

**必要パッケージ**: `typescript-eslint`, `eslint`, `eslint-config-prettier`, `prettier`

### API クライアント (lib/api.ts)

```typescript
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL ?? 'http://localhost:8080'

export async function apiFetch<T>(
  path: string,
  options?: RequestInit,
): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  })

  if (!res.ok) {
    throw new Error(`API error: ${res.status}`)
  }

  return res.json() as Promise<T>
}
```

※ `res.json()` は `Promise<any>` を返すため、`as Promise<T>` で明示キャストし `no-unsafe-return` を回避する。

### Expo Router レイアウト例 (app/_layout.tsx)

```tsx
import { Stack } from 'expo-router'

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ title: 'Home' }} />
    </Stack>
  )
}
```

## mise.toml への追記内容

```toml
[tools]
node = "22"

[tasks."dev:mobile"]
description = "Start Expo development server"
run = "cd {directory} && npx expo start"

[tasks."dev:mobile:ios"]
description = "Start Expo on iOS simulator"
run = "cd {directory} && npx expo start --ios"

[tasks."dev:mobile:android"]
description = "Start Expo on Android emulator"
run = "cd {directory} && npx expo start --android"
```

## dependabot.yml への追記内容

```yaml
- package-ecosystem: "npm"
  directory: "/{directory}"
  schedule:
    interval: "weekly"
```

## lint-staged への追記内容（ルート package.json）

```json
{
  "lint-staged": {
    "{directory}/**/*.{ts,tsx}": [
      "prettier --write",
      "eslint --fix"
    ]
  }
}
```

## CLAUDE.md への追記内容

```markdown
## モバイル（React Native / Expo）

```bash
mise run dev:mobile          # Expo dev サーバー起動
mise run dev:mobile:ios      # iOS シミュレーター起動
mise run dev:mobile:android  # Android エミュレーター起動
```
```

## 前提条件

- `init-project` が実行済み
- `mise` がインストール済み
- `node` が mise 経由でインストール可能
- iOS 開発時: Xcode がインストール済み
- Android 開発時: Android Studio がインストール済み

## EAS Build（将来の配信）

Expo Application Services (EAS) を使った配信は MVP 後に設定:

```bash
# EAS CLI インストール
npm install -g eas-cli

# EAS プロジェクト設定
cd {directory} && eas init

# 開発ビルド作成
eas build --profile development --platform ios
```

## よく使う追加パッケージ

| パッケージ | 用途 |
|-----------|------|
| `expo-notifications` | プッシュ通知 |
| `expo-secure-store` | セキュアストレージ（トークン保存） |
| `react-native-reanimated` | 高パフォーマンスアニメーション |
| `react-native-gesture-handler` | ジェスチャー操作 |
| `@tanstack/react-query` | サーバー状態管理 |
| `zustand` | クライアント状態管理 |
| `nativewind` | Tailwind CSS for React Native |
| `react-native-svg` | SVG 描画（進捗可視化に必要） |
| `expo-haptics` | 触覚フィードバック |

## 関連スキル

- `init-project`: プロジェクト基盤（先に実行）
- `init-go-backend`: Go バックエンドセットアップ
