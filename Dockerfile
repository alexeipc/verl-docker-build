# Start from NVIDIA PyTorch container
FROM nvcr.io/nvidia/pytorch:24.08-py3

# Environment
ENV MAX_JOBS=32
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_OPTIONS=""
ENV PIP_ROOT_USER_ACTION=ignore
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Use official PyPI
RUN pip config set global.index-url https://pypi.org/simple && \
    python -m pip install --upgrade pip

# System packages
RUN apt-get update && \
    apt-get install -y \
        wget \
        git \
        tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remove conflicting NVIDIA packages
RUN pip uninstall -y \
    torch torchvision torchaudio \
    pytorch-quantization \
    pytorch-triton \
    torch-tensorrt \
    transformer-engine \
    flash-attn \
    apex \
    megatron-core \
    xgboost \
    opencv-python \
    grpcio || true

# Fix broken cv2 from base image
RUN rm -rf /usr/local/lib/python3.10/dist-packages/cv2 || true

# Install PyTorch + vLLM stack
RUN pip install --no-cache-dir \
    "torch==2.7.0" \
    "torchvision==0.22.0" \
    "torchaudio==2.7.0" \
    "vllm==0.9.1" \
    tensordict \
    torchdata \
    "transformers>=4.51.0" \
    accelerate \
    datasets \
    peft \
    hf-transfer \
    "numpy<2.0.0" \
    "pyarrow>=15.0.0" \
    "grpcio>=1.62.1" \
    "optree>=0.13.0" \
    pandas \
    ray[default] \
    codetiming \
    hydra-core \
    pylatexenc \
    qwen-vl-utils \
    wandb \
    liger-kernel \
    mathruler \
    pytest \
    yapf \
    py-spy \
    pyext \
    pre-commit \
    ruff

# Install flash-attn
RUN ABI_FLAG=$(python -c "import torch; print('TRUE' if torch._C._GLIBCXX_USE_CXX11_ABI else 'FALSE')") && \
    URL="https://github.com/Dao-AILab/flash-attention/releases/download/v2.8.0.post2/flash_attn-2.8.0.post2+cu12torch2.7cxx11abi${ABI_FLAG}-cp310-cp310-linux_x86_64.whl" && \
    mkdir -p /opt/tiger && \
    wget -nv -P /opt/tiger "${URL}" && \
    pip install --no-cache-dir "/opt/tiger/$(basename ${URL})"

# Default shell
CMD ["/bin/bash"]
