# LightRAG Server

## Description

LightRAG Server is a lightweight server application that leverages the LightRAG framework for building retrieval-augmented generation (RAG) systems. It provides an easy-to-use interface for integrating various language models and vector databases to create powerful AI applications.

This project is built using Python and Docker, ensuring a consistent and portable environment for deployment.

LiteLLM is used as the primary language model interface, allowing for seamless integration with various LLM providers.

If you want to change the LLM provider, please edit the `.env` file and litellm_config.yaml file.

Now using OpenRouter as the default LLM provider with OSS-GPT-120b running in Cerebras super speed environment, and OpenAI as the embedding provider. Cohere is also supported as a reranking model provider.

## Prerequisites

- Docker installed on your machine.
- A `.env` file in the project root with necessary environment variables (you can copy from `.env.template` and fill in your actual API keys).

## Usage

### Build Docker Image

```bash
TAG="$(date +%Y.%-m.%-d)" && \
REPO="local/lightrag-server" && \
echo "Building ${REPO}:${TAG}" && \
docker buildx build \
--platform=linux/amd64 \
--output type=docker,name=${REPO}:${TAG},compression=zstd,oci-mediatypes=true,force-compression=true,compression-level=9 \
. && \
docker tag ${REPO}:${TAG} ${REPO}:latest
```

### Run Docker Container

for Windows (Git Bash):

```bash
CURRENT_DIR=$(pwd -W) && \
REPO="local/lightrag-server" && \
docker run \
-p 9621:9621 \
--env-file ${CURRENT_DIR}/.env \
--rm -it \
-v ${CURRENT_DIR}/.settings.lightrag:/workspace/.env \
-v ${CURRENT_DIR}/inputs:/workspace/inputs \
-v ${CURRENT_DIR}/rag_storage:/workspace/rag_storage \
${REPO}:latest
```

for Linux/Mac:

```bash
CURRENT_DIR=$(pwd) && \
REPO="local/lightrag-server" && \
docker run \
-p 9621:9621 \
--env-file ${CURRENT_DIR}/.env \
--rm -it \
-v ${CURRENT_DIR}/.settings.lightrag:/workspace/.env \
-v ${CURRENT_DIR}/inputs:/workspace/inputs \
-v ${CURRENT_DIR}/rag_storage:/workspace/rag_storage \
${REPO}:latest
```
