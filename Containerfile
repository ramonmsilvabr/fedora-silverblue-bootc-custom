FROM registry.fedoraproject.org/fedora-silverblue:43
# Baixa o binário do Github para instalar na imagem base
RUN curl -o https://github.com/ramonmsilvabr/silverblue-akmods-keys/releases/download/0.0.2-8-1/akmods-keys-0.0.2-8.fc43.noarch.rpm
# Habilitar repositórios free e non-free 
RUN rpm-ostree install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm
RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# Instala os pacotes no ambiente
RUN rpm-ostree install kernel-devel \
    akmods akmod-nvidia \
    xorg-x11-drv-nvidia-cuda \
    distrobox \
    libgda \
    libgda-sqlite \
    podman-compose \
    tuned-utils]

RUN ostree container commit