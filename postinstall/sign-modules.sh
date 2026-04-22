#!/usr/bin/bash
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
# Configurações - Altere os caminhos para onde estão seus arquivos
PRIV_KEY="akmods.priv"
DER_CERT="akmods.der"

# 1. Localizar o utilitário sign-file no Silverblue/Fedora
# O link 'build' em /lib/modules sempre aponta para os headers do kernel atual
SIGN_FILE="/usr/lib/modules/$KERNEL_VERSION/build/scripts/sign-file"

if [ ! -f "$SIGN_FILE" ]; then
    echo "Erro: Utilitário sign-file não encontrado."
    echo "Certifique-se de que o pacote 'kernel-devel' está instalado (rpm-ostree install kernel-devel)."
    exit 1
fi

TARGET_DIR="/usr/lib/modules/$KERNEL_VERSION/extra/"

# 2. Busca e Processamento
# O find busca arquivos que terminam em .ko ou variações compactadas
find "$TARGET_DIR" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "*.ko.zst" \) | while read -r MODULE_PATH; do

    EXTENSION="${MODULE_PATH##*.}"
    RECOMPRESS=""
    CURRENT_FILE="$MODULE_PATH"

    # 3. Tratamento de compactação
    if [ "$EXTENSION" == "xz" ]; then
        echo "Descompactando: $MODULE_PATH"
        sudo xz -d "$MODULE_PATH"
        CURRENT_FILE="${MODULE_PATH%.xz}"
        RECOMPRESS="xz"
    elif [ "$EXTENSION" == "zst" ]; then
        echo "Descompactando: $MODULE_PATH"
        sudo unzstd --rm "$MODULE_PATH"
        CURRENT_FILE="${MODULE_PATH%.zst}"
        RECOMPRESS="zstd"
    fi

    # 4. Assinatura
    echo "Assinando: $CURRENT_FILE"
    sudo "$SIGN_FILE" sha256 "$PRIV_KEY" "$DER_CERT" "$CURRENT_FILE"

    # 5. Recompactação
    if [ "$RECOMPRESS" == "xz" ]; then
        echo "Recompactando em XZ..."
        sudo xz -f -C crc32 "$CURRENT_FILE"
    elif [ "$RECOMPRESS" == "zstd" ]; then
        echo "Recompactando em ZST..."
        sudo zstd --rm -19 -f "$CURRENT_FILE"
    fi

done

echo "Processo concluído!"