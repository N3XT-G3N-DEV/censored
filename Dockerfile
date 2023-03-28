# GPTQ-for-LLaMa and Text Generation WebUI Dockerfile
FROM nvidia/cuda:11.7.0-devel-ubuntu22.04 as builder

RUN apt-get update && \
    apt-get install --no-install-recommends -y git build-essential python3-dev python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip pip3 install torch torchvision torchaudio
RUN git clone https://github.com/qwopqwop200/GPTQ-for-LLaMa /build

WORKDIR /build

ARG GPTQ_SHA
RUN git reset --hard ${GPTQ_SHA}

RUN --mount=type=cache,target=/root/.cache/pip pip3 install -r requirements.txt

# https://developer.nvidia.com/cuda-gpus
# for a rtx 2060: ARG TORCH_CUDA_ARCH_LIST="7.5"
ARG TORCH_CUDA_ARCH_LIST="3.5;5.0;6.0;6.1;7.0;7.5;8.0;8.6+PTX"
RUN python3 setup_cuda.py bdist_wheel -d .

FROM ubuntu:22.04

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Docker image for GPTQ-for-LLaMa and Text Generation WebUI"

RUN apt-get update && \
    apt-get install --no-install-recommends -y git python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip pip3 install torch torchvision torchaudio

RUN git clone https://github.com/oobabooga/text-generation-webui /app

WORKDIR /app

ARG WEBUI_SHA=HEAD
RUN git reset --hard ${WEBUI_SHA}

RUN --mount=type=cache,target=/root/.cache/pip pip3 install -r requirements.txt

COPY --from=builder /build /app/repositories/GPTQ-for-LLaMa
RUN --mount=type=cache,target=/root/.cache/pip pip3 install /app/repositories/GPTQ-for-LLaMa/*.whl

ENV CLI_ARGS=""
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN --mount=type=cache,target=/root/.cache/pip cd extensions/api && pip3 install -r requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd extensions/elevenlabs_tts && pip3 install -r requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd extensions/google_translate && pip3 install -r requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd extensions/silero_tts && pip3 install -r requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip cd extensions/whisper_stt && pip3 install -r requirements.txt

CMD python3 server.py ${CLI_ARGS}
