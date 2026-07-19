# Imagem do Fedora Silverblue OCI com modificações

Essa imagem pode ser utilizada se desejar uma instalação mais limpa do Fedora sem ter que recorrer a sistemas que trazem várias modificações.
Duas edições principais: 
* `fedora-silverblue-bootc-custom` que **apenas** inclui os drivers Open Source; 
* `fedora-silverblue-bootc-custom-nvidia-open` que inclui os drivers proprietários da NVIDIA.
Canais de atualização:
|Canal|Versão atual|Recorrência de build|
|---|---|---|
|latest|44|Diária|
|beta|45|Ocasional|
|old|43|Ocasional|
* Drivers fora da árvore inclusos:
    * xpadneo: Xbox Advanced Linux Driver; Repositório terra.
    * nvidia (na edição nvidia-open): NVIDIA Open Kernel Modules; Repositório rpmfusion.
Ambiente Desktop/Compositor Wayland: GNOME Shell/Mutter
Imagem base: Fedora Silverblue bootc

# Buildar localmente

* Clone o repositório e crie um container com a imagem

```
# Clonagem do repositório
git clone https://github.com/ramonmsilvabr/fedora-silverblue-bootc-custom.git
cd fedora-silverblue-bootc-custom
# Apenas drivers Open Source
sudo podman build --build-arg SECUREBOOT_IGNORE=true -t fedora-silverblue-bootc-custom-nvidia-open . -f nvidia-open/Containerfile
# Com drivers proprietários da NVIDIA
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
# Uso da imagem no registro do Github Actions

* Se você usa Secure Boot, importe o certificado antes de instalar:

    ```
    git clone https://github.com/ramonmsilvabr/fedora-silverblue-bootc-custom.git
    cd fedora-silverblue-bootc-custom/secureboot
    sudo mokutil -i MOK.der
    #  Importe a chave no MOK com uma senha de sua preferência, digite-a duas vezes
    ```

* Separo em três canais, o canal **latest**  possui a última versão estável do Fedora, o **beta** possui a próxima versão e o **old** possui a versão que está ainda sendo suportada sem ser a mais atual. Se você preferir, você pode escolher uma versão específica por número: ex. 44, 45 e 43.

* Se você quer gerar uma ISO, utilize o bootc-image-builder numa distro do Fedora ou derivados (CentOS e RHEL).

    * Imagem com drivers Open Source apenas:

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
        ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom:<versão>
    ```

    * Imagem que inclui o driver proprietário da NVIDIA:

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
        ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom-nvidia-open:<version>
    ```

* Se você já estiver em qualquer edição atômica do Fedora ou derivados, você pode puxar a imagem direto do registro.

    * Edição com drivers da NVIDIA:
    ```
    sudo bootc switch ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom-nvidia-open:<versão>
    ```

    * Edição sem drivers da NVIDIA:
    ```
    sudo bootc switch ghcr.io/ramonmsilvabr/fedora-silverblue-bootc-custom:<versão>
    ```