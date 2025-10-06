# syntax=docker/dockerfile:1.4

ARG CUDA_VERSION=12.6.3
ARG IMAGE_TYPE=cudnn-runtime
ARG OS_VERSION=ubuntu22.04
ARG PYTHON_VERSION=3.12
ARG DEBIAN_FRONTEND=noninteractive

FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-${IMAGE_TYPE}-${OS_VERSION} AS builder
SHELL ["/usr/bin/bash", "-c"]

ARG PYTHON_VERSION
ARG DEBIAN_FRONTEND

# Install APT Packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
    curl \
    git \
    unattended-upgrades && \
    unattended-upgrades -v && \
    rm -rf /usr/local/src/*

# Setup Project
RUN mkdir -p /workspace
WORKDIR /workspace

# Install UV and Python
RUN touch ~/.bashrc && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:${PATH}"
ENV UV_LINK_MODE=copy
ENV UV_COMPILE_BYTECODE=0

RUN uv self update && \
    uv python install ${PYTHON_VERSION} && \
    uv python pin ${PYTHON_VERSION}

# Copy Application Files
COPY README.md .
COPY pyproject.toml .

RUN --mount=type=cache,id=uv-cache,target=/root/.cache/uv \
    uv lock && \
    uv sync --locked --no-install-project

COPY litellm_config.yaml .
COPY launch.sh .
RUN chmod +x launch.sh

FROM nvcr.io/nvidia/cuda:${CUDA_VERSION}-${IMAGE_TYPE}-${OS_VERSION} AS final
SHELL ["/usr/bin/bash", "-c"]

ARG PYTHON_VERSION
ARG DEBIAN_FRONTEND

# Install APT Packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,id=apt-cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt-cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
    curl \
    git \
    unattended-upgrades && \
    unattended-upgrades -v && \
    rm -rf /usr/local/src/*


COPY --from=builder /root/.local /root/.local
COPY --from=builder /workspace /workspace
WORKDIR /workspace

RUN touch ~/.bashrc && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

RUN mkdir -p /workspace/src/nakahara_lightrag
RUN touch /workspace/src/nakahara_lightrag/__init__.py

ENV PATH="/root/.local/bin:${PATH}"
ENV UV_LINK_MODE=copy
ENV UV_COMPILE_BYTECODE=1
ENV HOST=0.0.0.0 PORT=9621
EXPOSE 9621 4000

CMD ["bash", "launch.sh"]
