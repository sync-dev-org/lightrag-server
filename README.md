# LightRAG Server

## 概要

[LightRAG](https://github.com/HKUDS/LightRAG)フレームワークをベースに、一定の設定を行い、簡単に起動できるようにDockerコンテナ化されたRAG（Retrieval-Augmented Generation）サーバーです。

## システム要件

- Docker Desktop または Docker Engine
- 8GB以上のRAM推奨
- インターネット接続（APIアクセス用）

## セットアップ

### 1. リポジトリのクローン

```bash
docker pull ghcr.io/sync-dev-org/lightrag-server:latest
```

### 2. 環境変数の設定

`.env.template`をコピーして`.env`ファイルを作成し、必要なAPIキーを設定します：

```bash
cp .env.template .env
```

`.env`ファイルを編集して、以下のAPIキーを設定：

```env
COHERE_API_KEY=your_cohere_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

この.envファイルは、Dockerコンテナ起動時に`--env-file`オプションでコンテナの環境変数として読み込まれます。

### 3. 設定のカスタマイズ

`.settings.lightrag`ファイルで、LightRAGの詳細な設定が可能です：
ややこしいですが、`.settings.lightrag`はコンテナ起動時に、`-v ${CURRENT_DIR}/.settings.lightrag:/workspace/.env`でマウントされます。これは、環境変数としてではなく、LightRAGの設定ファイルが`.env`というファイル名を要求するからです。


- **言語設定**: `SUMMARY_LANGUAGE=Japanese`（日本語処理の場合）
- **チャンクサイズ**: `CHUNK_SIZE=1500`（文書の分割サイズ）
- **並列処理数**: `MAX_PARALLEL_INSERT=4`（同時処理文書数）
- **埋め込み並列数**: `EMBEDDING_FUNC_MAX_ASYNC=4`

## Dockerを使用した起動方法

### コンテナの Pull

```bash
docker pull ghcr.io/sync-dev-org/lightrag-server:latest
```

### コンテナの起動

#### Windows (Git Bash)の場合：

```bash
CURRENT_DIR=$(pwd -W) && \
REPO="ghcr.io/sync-dev-org/lightrag-server" && \
docker run \
-p 9621:9621 \
--env-file ${CURRENT_DIR}/.env \
--rm -it \
-v ${CURRENT_DIR}/.settings.lightrag:/workspace/.env \
-v ${CURRENT_DIR}/inputs:/workspace/inputs \
-v ${CURRENT_DIR}/rag_storage:/workspace/rag_storage \
${REPO}:latest
```

#### Linux/macOSの場合：

```bash
CURRENT_DIR=$(pwd) && \
REPO="ghcr.io/sync-dev-org/lightrag-server" && \
docker run \
-p 9621:9621 \
--env-file ${CURRENT_DIR}/.env \
--rm -it \
-v ${CURRENT_DIR}/.settings.lightrag:/workspace/.env \
-v ${CURRENT_DIR}/inputs:/workspace/inputs \
-v ${CURRENT_DIR}/rag_storage:/workspace/rag_storage \
${REPO}:latest
```

## API エンドポイント

サーバー起動後、以下のエンドポイントが利用可能になります：

### Web UI
- **ローカルアクセス**: http://localhost:9621
- **リモートアクセス**: http://<your-ip-address>:9621

### API ドキュメント
- **Swagger UI**: http://localhost:9621/docs
- **ReDoc**: http://localhost:9621/redoc

### 主要なAPIエンドポイント

- `POST /documents/scan` - inputsディレクトリの文書をスキャンしてインデックス作成
- `POST /documents/upload` - 文書を直接アップロードしてインデックス作成
- `POST /query` - クエリを実行し、LLMからの応答を取得
- `POST /query/stream` - ストリーミングでクエリを実行し、LLMからの応答をリアルタイムで取得
- `POST /query/data` - クエリを実行し、生データ形式で応答を取得
- `GET /health` - サーバーの健康状態を確認

## 使用方法

### 1. 文書の追加

文書を`inputs/`ディレクトリに配置してから、以下のいずれかの方法でインデックス作成：

- Web UIから「Scan Documents」をクリック
- APIで `/documents/scan` エンドポイントを呼び出し

### 2. クエリの実行

インデックス作成後、Web UIまたはAPIを使用してクエリを実行：

```bash
curl -X POST http://localhost:9621/query \
  -H "Content-Type: application/json" \
  -d '{　"query": "Who is Nakahara" }'
```

## プロジェクト構造

```
lightrag-server/
├── .env.template        # 環境変数テンプレート
├── .settings.lightrag   # LightRAG設定ファイル
├── Dockerfile          # Dockerイメージ定義
├── LICENSE            # MITライセンス
├── README.md          # このファイル
├── inputs/            # 処理する文書を配置するディレクトリ
├── launch.sh          # 起動スクリプト
├── litellm_config.yaml # LiteLLM設定
├── pyproject.toml     # Pythonプロジェクト設定
└── rag_storage/       # インデックスデータ保存ディレクトリ
```

## LLMプロバイダーの変更

デフォルトでは以下のプロバイダーを使用：

- **メインLLM**: OpenRouter経由のOSS-GPT-120b (Cerebras)
- **埋め込み**: OpenAI text-embedding-3-small
- **リランキング**: Cohere rerank-v3.5

プロバイダーを変更する場合は、`.settings.lightrag`と`litellm_config.yaml`を編集：

```yaml
model_list:
  - model_name: your-model-name
    litellm_params:
      model: provider/model-path
      api_key: os.environ/YOUR_API_KEY
```

## トラブルシューティング

### よくある問題と解決方法

1. **APIキーエラー（401 Unauthorized）**
   - `.env`ファイルのAPIキーが正しく設定されているか確認
   - 環境変数に余分な引用符が含まれていないか確認

2. **Rate Limit エラー（429 Too Many Requests）**
   - `.settings.lightrag`で`EMBEDDING_FUNC_MAX_ASYNC`の値を減らす
   - `MAX_PARALLEL_INSERT`の値を調整

3. **メモリ不足エラー**
   - Dockerのメモリ制限を増やす
   - `CHUNK_SIZE`を小さくする

## 開発

### ローカル開発環境のセットアップ

```bash
# UV のインストール
curl -LsSf https://astral.sh/uv/install.sh | sh

# 依存関係のインストール
uv sync

# 開発サーバーの起動
uv run python -m lightrag_server
```

### Dockerイメージのビルド

```bash
TAG="$(date +%Y.%-m.%-d)" && \
REPO="ghcr.io/sync-dev-org/lightrag-server" && \
echo "Building ${REPO}:${TAG}" && \
docker buildx build \
--platform=linux/amd64 \
--output type=docker,name=${REPO}:${TAG},compression=zstd,oci-mediatypes=true,force-compression=true,compression-level=9 \
. && \
docker tag ${REPO}:${TAG} ${REPO}:latest
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 謝辞

- [LightRAG](https://github.com/HKUDS/LightRAG) - HKUDSチーム
- [LiteLLM](https://github.com/BerriAI/litellm) - BerriAI
- [UV](https://github.com/astral-sh/uv) - Astral
