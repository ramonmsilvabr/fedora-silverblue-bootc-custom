# Imagem do Fedora Silverblue OCI com modificações

Duas versões principais: 
* `fedora-silverblue-bootc-custom` que **não** inclui os drivers proprietários da NVIDIA; 
* `fedora-silverblue-bootc-custom-nvidia-open` que inclui os drivers proprietários sem as dependências de compilação.

As duas imagens são baseadas no Fedora Silverblue, isso significa que o ambiente Desktop de escolha é o GNOME na sua versão mais recente.

Essa imagem não oferece suporte a Secure Boot se não passar as chaves customizadas no build, então, para mantê-lo ativado você precisa de um **fork** do repositório, uma vez que não disponibilizo as chaves.

# Como instalar

* Clone o repositório e crie um container com a imagem

```
# Clonagem do repositório
git clone https://github.com/ramonmsilvabr/fedora-silverblue-bootc-custom.git
cd fedora-silverblue-bootc-custom
# Com drivers nvidia
sudo podman build --build-arg SECUREBOOT_IGNORE=true -t fedora-silverblue-bootc-custom-nvidia-open . -f nvidia-open/Containerfile
# Sem drivers nvidia
sudo podman build --build-arg SECUREBOOT_IGNORE=true -t fedora-silverblue-bootc-custom . -f default/Containerfile
```

* Se precisar da ISO para fazer uma instalação limpa:

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

* Se você já estiver em qualquer edição atômica do Fedora ou derivados, você pode puxar a imagem direto do registro. Note que não tem suporte a Secure Boot.

    * Edição com drivers da NVIDIA:
    ```
    sudo bootc switch ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom-nvidia-open:latest
    ```

    * Edição sem drivers da NVIDIA:
    ```
    sudo bootc switch ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom:latest
    ```