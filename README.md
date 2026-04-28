# Fedora Silverblue para laptop híbrido NVIDIA + INTEL

* Incluído módulos de Kernel já compilados:
    * NVIDIA Linux Open Kernel Modules - nvidia-kmod;
    * Advanced Xbox Wireless Controller Driver - xpadneo-kmod;
* Incluído drivers:
    * Bibliotecas para o driver da NVIDIA com suporte a NVIDIA-SMI e SELinux;
    * PPDs para impressoras Samsung;    

Os módulos da imagem não carregarão em sistemas com Secure Boot on, se precisar assinar sua versão, sinta-se livre para forkear o Repo e adicionar suas próprias chaves.

| **Itens**  | **Informações** |
| ------------- |:-------------:|
| Base    | Fedora Silverblue     |
| Versão atual  | 44                    |
| Ambiente Desktop | GNOME Shell 50.x   |
| Repositório NVIDIA | https://negativo17.org/ |

# Como instalar

## Clone o repositório e crie um container com a imagem

```
git clone https://github.com/ramonmsilvabr/fedora-bootc-gnome-nvidia-open.git
cd fedora-bootc-gnome-nvidia-open.git
mkdir output
# Caso você use a imagem sem Secure Boot
sudo podman build --build-arg SECUREBOOT_IGNORE=true -t fedora-bootc-gnome-nvidia-open -f Containerfile
# Caso você use o repo forkeado com Secure Boot
sudo podman build -t <forked_repo> -f Containerfile
```


## Criar ISO para instalar do zero.

```
sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v ./output:/output \
    -v ./config.toml:/config.toml:ro \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    --rootfs btrfs \
    localhost/fedora-bootc-gnome-nvidia-open
```