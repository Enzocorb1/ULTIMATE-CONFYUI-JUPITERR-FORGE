# 1. Base officielle Nvidia avec Python 3.11 et CUDA 12.4
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# Configuration système de base
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 2. Installation des dépendances Linux indispensables
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    git \
    git-lfs \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    aria2 \
    && rm -rf /var/lib/apt/lists/*

# Liaison de python3 vers python
RUN ln -s /usr/bin/python3.11 /usr/bin/python && ln -s /usr/bin/pip3 /usr/bin/pip

# 3. Mise à jour de PyTorch pour l'accélération GPU (RTX 3090 / 5090)
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://pytorch.org

# 4. Installation de JupyterLab et des modules de manipulation d'images
RUN pip install --no-cache-dir jupyterlab safetensors einops altair matplotlib

# 5. Création de l'espace de travail et installation de Stable Diffusion Forge
WORKDIR /workspace
RUN git clone https://github.com forge \
    && cd forge && pip install -r requirements_versions.txt

# 6. Installation de ComfyUI
RUN git clone https://github.com comfyui \
    && cd comfyui && pip install -r requirements.txt

# 7. Création d'un script de démarrage automatique pour lancer les 3 outils d'un coup
RUN echo '#!/bin/bash\n\
# Lancement de JupyterLab sur le port 8888\n\
nohup jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token="" --NotebookApp.password="" > /var/log/jupyter.log 2>&1 &\n\
# Lancement de ComfyUI sur le port 8188\n\
nohup python /workspace/comfyui/main.py --listen 0.0.0.0 --port 8188 > /var/log/comfyui.log 2>&1 &\n\
# Lancement de Forge en premier plan sur le port 7860\n\
python /workspace/forge/launch.py --listen --port 7860 --enable-insecure-extension-access\n\
' > /start.sh && chmod +x /start.sh

# Configuration des ports exposés par défaut
EXPOSE 7860 8188 8888

# Commande de démarrage au lancement du Pod
CMD ["/start.sh"]
