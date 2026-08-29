#!/usr/bin/bash

# Pega versão do pacote de kernel do Fedora
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
# Configurações - Altere os caminhos para onde estão seus arquivos
PRIV_KEY="./secureboot/MOK.priv"
DER_CERT="./secureboot/MOK.der"

chmod 444 $DER_CERT
chmod 400 $PRIV_KEY

echo "Instalando kernel-devel"
dnf install -y kernel-devel 

# kernel-devel provem o código fonte e o utilitário de assinatura
SIGN_FILE="/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file"

# Filtra a existência do utilitário de assinatura
if [ ! -f "$SIGN_FILE" ]; then
    exit 1
fi

# Diretório dos módulos de kernel
TARGET_DIR="/usr/lib/modules/${KERNEL_VERSION}/extra/"

# Checa a existência de módulos compactados no TARGET_DIR
find "$TARGET_DIR" -type f \( -name "*.ko" -o -name "*.ko.xz" -o -name "*.ko.zst" \) | while read -r MODULE_PATH; do
    EXTENSION="${MODULE_PATH##*.}"
    RECOMPRESS=""
    CURRENT_FILE="$MODULE_PATH"
    if [ "$EXTENSION" == "xz" ]; then
        xz -d "$MODULE_PATH"
        CURRENT_FILE="${MODULE_PATH%.xz}"
        RECOMPRESS="xz"
    elif [ "$EXTENSION" == "zst" ]; then
        unzstd --rm "$MODULE_PATH"
        CURRENT_FILE="${MODULE_PATH%.zst}"
        RECOMPRESS="zstd"
    fi
    "$SIGN_FILE" sha256 "$PRIV_KEY" "$DER_CERT" "$CURRENT_FILE"
    if [ "$RECOMPRESS" == "xz" ]; then
        xz -f -C crc32 "$CURRENT_FILE"
    elif [ "$RECOMPRESS" == "zstd" ]; then
        zstd --rm -19 -f "$CURRENT_FILE"
    fi
done

rm -rfv "$PRIV_KEY" "$DER_CERT"

# Limpa kernel-devel
dnf remove -y kernel-devel 