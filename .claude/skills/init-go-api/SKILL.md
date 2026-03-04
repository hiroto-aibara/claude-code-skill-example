---
name: init-go-api
description: Generate Web API infrastructure code (middleware, response helpers, domain errors, main.go with graceful shutdown). Run after init-go-backend.
allowed-tools: Bash, Write, Read, Edit
---

# Init Go API

`/init-go-backend` 実行後に使用。Web API に必要なインフラコード（ミドルウェア、レスポンスヘルパー、ドメインエラー型、main.go）を生成する。

## 概要

このスキルは以下を実行します：

```
1. 情報収集（対話）
   - アプリ名（例: myapi → cmd/myapi/ で使用）
   - CORS 許可オリジン（デフォルト: http://localhost:3000）
   - Rate Limit 設定（デフォルト: 100req/min, burst 100）
        ↓
2. 依存パッケージ追加
   - go get github.com/google/uuid golang.org/x/time
        ↓
3. ドメインエラー型生成
   - internal/domain/errors.go（汎用 5 型）
   - internal/domain/errors_test.go
        ↓
4. ハンドラーインフラ生成
   - internal/handler/middleware.go（6 種のミドルウェア）
   - internal/handler/middleware_test.go
   - internal/handler/response.go（レスポンスヘルパー）
   - internal/handler/response_test.go
   - internal/handler/context.go（コンテキストヘルパー）
        ↓
5. main.go 生成
   - cmd/<app-name>/main.go（DI 配線 + graceful shutdown + /health）
        ↓
6. 動作確認
   - mise run test → グリーン
   - mise run lint → エラーなし
```

## 使用方法

```bash
/init-go-api
```

## 前提条件

- `/init-go-backend` が実行済み（ディレクトリ構造 + linter + mise タスクが存在）
- `go.mod` が存在する

## 追加する依存パッケージ

```
github.com/google/uuid       # UUID 生成・バリデーション
golang.org/x/time            # Rate Limiter (token bucket)
```

## 生成ファイル一覧

### 新規作成（計 8 ファイル）

```
cmd/<app-name>/
  main.go                        # DI 配線 + graceful shutdown + /health

internal/
  domain/
    errors.go                    # 汎用 5 エラー型
    errors_test.go               # エラー型テスト
  handler/
    middleware.go                # ミドルウェア一式（6 種）
    middleware_test.go           # ミドルウェアテスト
    response.go                  # レスポンスヘルパー
    response_test.go             # レスポンスヘルパーテスト
    context.go                   # コンテキストヘルパー
```

---

## 各ファイルの詳細仕様

### internal/domain/errors.go — ドメインエラー型

汎用 5 型。各型は `Error() string` を実装する。

| エラー型 | フィールド | HTTP ステータス（handler で変換） | 用途 |
|---|---|---|---|
| `ErrNotFound` | Resource, ID string | 404 | リソース未検出 |
| `ErrValidation` | Field, Message string | 400 | 入力バリデーション失敗 |
| `ErrConflict` | Resource, ID string | 409 | 重複リソース |
| `ErrUnauthorized` | Message string | 401 | 認証失敗 |
| `ErrForbidden` | Message string | 403 | 認可失敗 |

### internal/handler/middleware.go — ミドルウェア一式

3 層に分類される 6 種のミドルウェア:

#### インフラ層（全リクエストに適用）

| ミドルウェア | シグネチャ | 役割 |
|---|---|---|
| `RequestID` | `func(http.Handler) http.Handler` | `X-Request-ID` ヘッダーを生成（リクエストに含まれていればそれを使用、なければ `uuid.New()` で生成）。slog のログ出力にも紐付く |
| `CORS` | `func(CORSConfig) func(http.Handler) http.Handler` | `CORSConfig{AllowedOrigins, AllowedMethods, AllowedHeaders, MaxAge}` に基づくオリジンホワイトリスト + preflight (OPTIONS) 対応。`Vary: Origin` ヘッダー設定 |
| `SecurityHeaders` | `func(http.Handler) http.Handler` | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin` を設定 |
| `CacheControl` | `func(http.Handler) http.Handler` | `Cache-Control: no-store` を設定。API レスポンスのキャッシュを防止 |

#### 防御層（全リクエストまたはルートグループに適用）

| ミドルウェア | シグネチャ | 役割 |
|---|---|---|
| `RateLimiter` | `NewRateLimiter(RateLimitConfig) *RateLimiter` / `.Handler() func(http.Handler) http.Handler` | per-IP token bucket。`golang.org/x/time/rate` ベース。`sync.Map` でリミッター管理、background goroutine で古いエントリをクリーンアップ。`StopCleanup()` で停止。`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` ヘッダー設定 |

#### 処理層（特定ルートに適用）

| ミドルウェア | シグネチャ | 役割 |
|---|---|---|
| `ValidateUUIDParam` | `func(paramName string) func(http.Handler) http.Handler` | chi の `URLParam` から取得した値を `uuid.Parse` で検証。不正なら 400 レスポンス |

#### 補助型

```go
type CORSConfig struct {
    AllowedOrigins []string
    AllowedMethods []string
    AllowedHeaders []string
    MaxAge         int // preflight cache duration in seconds
}

type RateLimitConfig struct {
    Rate  rate.Limit // requests per second
    Burst int        // burst size
}
```

### internal/handler/response.go — レスポンスヘルパー

| 関数 | 役割 |
|---|---|
| `respondJSON(w http.ResponseWriter, status int, data any)` | Content-Type: application/json + ステータスコード + JSON エンコード |
| `writeError(w http.ResponseWriter, err error)` | `errors.As()` で domain エラー型を判別し、対応する HTTP ステータスで応答。未知のエラーは 500 + slog.Error |
| `errorResponse(code, message string) map[string]any` | `{"error":{"code":"...","message":"..."}}` 構造を返す |
| `decodeJSON(r *http.Request, dst any) error` | `http.MaxBytesReader` で 1MB 制限 + `DisallowUnknownFields()` + デコード失敗時は `ErrValidation` を返す |

### internal/handler/context.go — コンテキストヘルパー

```go
type contextKey string                                    // 型安全なコンテキストキー
func withUserID(ctx context.Context, userID string) context.Context  // コンテキストに UserID を保存
func UserIDFromContext(ctx context.Context) (string, error)          // コンテキストから UserID を取得
```

### cmd/{app}/main.go — エントリポイント

```go
func main() {
    // 1. 環境変数読み込み
    //    PORT (デフォルト: "8080")
    //    CORS_ALLOWED_ORIGINS (デフォルト: 対話で設定した値)

    // 2. Rate Limiter 初期化
    //    generalLimiter := handler.NewRateLimiter(handler.RateLimitConfig{...})
    //    defer generalLimiter.StopCleanup()

    // 3. CORS 設定
    //    corsConfig := handler.CORSConfig{...}

    // 4. chi Router + ミドルウェアスタック
    //    r := chi.NewRouter()
    //    r.Use(middleware.Logger)      // chi 標準
    //    r.Use(middleware.Recoverer)   // chi 標準
    //    r.Use(handler.RequestID)
    //    r.Use(handler.CORS(corsConfig))
    //    r.Use(handler.SecurityHeaders)
    //    r.Use(handler.CacheControl)

    // 5. /health エンドポイント
    //    r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
    //        w.WriteHeader(http.StatusOK)
    //        _, _ = w.Write([]byte("ok"))
    //    })

    // 6. /api/v1 ルートグループ
    //    r.Route("/api/v1", func(r chi.Router) {
    //        r.Use(generalLimiter.Handler())
    //        // ここにルートを追加
    //    })

    // 7. Graceful shutdown
    //    srv := &http.Server{Addr: ":" + port, Handler: r}
    //    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    //    defer stop()
    //    go func() {
    //        slog.Info("server starting", "port", port)
    //        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
    //            slog.Error("server failed", "error", err)
    //            os.Exit(1)
    //        }
    //    }()
    //    <-ctx.Done()
    //    slog.Info("shutting down server...")
    //    shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    //    defer cancel()
    //    if err := srv.Shutdown(shutdownCtx); err != nil {
    //        slog.Error("server shutdown failed", "error", err)
    //    }
}
```

**ミドルウェア適用順序の意図:**

```
Logger        — 全リクエストを記録（最初に適用）
Recoverer     — panic 回復（Logger の後）
RequestID     — リクエスト追跡用 ID 付与
CORS          — クロスオリジン制御
SecurityHeaders — セキュリティヘッダー設定
CacheControl  — キャッシュ防止
```

---

## 含めないもの（プロジェクト固有）

| コンポーネント | 理由 |
|---|---|
| `AuthMiddleware` (JWT) | 認証方式はプロジェクトごとに異なる。必要時に手動追加 |
| `Request Timeout` | chi 標準の `middleware.Timeout` で対応可能 |
| `Content-Type 検証` | `decodeJSON` 内で実質担保 |
| `HSTS` | HTTPS 前提。ローカル開発で邪魔になる |
| ドメインエンティティ | プロジェクト固有 |
| ユースケース・ハンドラー実装 | プロジェクト固有 |
| DB 接続 (pgx) | 全プロジェクトで DB を使うとは限らない。必要時に追加 |

## 完了後の保証

- `mise run dev` → `curl localhost:8080/health` で HTTP 200 が返る
- `mise run test` がグリーンで通る
- `mise run lint` がエラーなしで通る

## 関連スキル

- `init-go-backend`: Go 基盤セットアップ（先に実行）
- `init-project`: プロジェクト基盤（最初に実行）
