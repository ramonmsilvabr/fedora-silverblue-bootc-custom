# Fedora Silverblue com algumas baterias

* Incluído módulos de Kernel já compilados:
    * NVIDIA Linux Open Kernel Modules - nvidia-kmod; - na branch master apenas
    * Advanced Xbox Wireless Controller Driver - xpadneo-kmod;
* Incluído drivers:
    * Bibliotecas para o driver da NVIDIA com suporte a NVIDIA-SMI e SELinux; - na branch master apenas
    * PPDs para impressoras Samsung;
    * Suporte a uso de aceleração gráfica da NVIDIA nos containers.    

Os módulos da imagem não carregarão em sistemas com Secure Boot on, se precisar assinar sua versão, sinta-se livre para forkear o Repo e adicionar suas próprias chaves.

| **Itens**  | **Informações** |
| ------------- |:-------------:|
| Base    | Fedora Silverblue     |
| Versão padrão atual  | 44                    |
| Ambiente Desktop | GNOME Shell 50.x   |
| Repositório NVIDIA | https://negativo17.org/ |

# Como instalar

## Clone o repositório e crie um container com a imagem

```
# Clonagem do repositório
git clone https://github.com/ramonmsilvabr/fedora-silverblue-bootc-custom.git
cd fedora-silverblue-bootc-custom
```
No repositório **master**, os drivers da nvidia estão incluídos, caso você queira utilizar a versão sem os drivers proprietários e usar os drivers open-source apenas faça o checkout para a branch non-nvidia.
```
# Checkout para a branch non-nvidia
git checkout non-nvidia
```

```
mkdir output
# Caso você use a imagem sem Secure Boot
sudo podman build --build-arg SECUREBOOT_IGNORE=true -t fedora-silverblue-bootc-custom -f Containerfile
# Caso você use o repo forkeado com Secure Boot
sudo podman build -t <forked_repo> -f Containerfile
```


## Criar ISO para instalar do zero.

Aqui você roda o container que você baixou e produz a iso sem o Secure Boot

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
    localhost/fedora-silverblue-bootc-custom
```

Para rodar com suporte a secure boot, chame seu registro 
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
    <seu registro/imagem>
```