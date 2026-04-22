# Imagem para compilar os módulos de kernel
FROM quay.io/fedora/fedora-bootc:44 AS builder

RUN <<EOF 
set -e

echo "Atualizando o pacote do Linux Kernel"
dnf5 upgrade -y 'kernel*' --refresh

echo "Instalando pacotes de desenvolvimento do Kernel"
dnf5 install -y kernel-devel openssl perl-devel mokutil keyutils --refresh

# Variável para ter a versão do kernel atual
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

echo "Instalando pacotes plugins de COPR e Repositórios"
dnf5 install -y 'dnf5-command(config-manager)' 'dnf5-command(copr)'

echo "Adicionando repositórios da NVIDIA e do xpadneo para compilação"
dnf5 copr enable -y sentry/xpadneo
dnf5 config-manager addrepo -y --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo
EOF

RUN <<EOF 
set -e

echo "Instalando drivers e ferramentas de compilação dos módulos"
dnf5 install -y nvidia-driver nvidia-open nvidia-driver-cuda \
xpadneo --refresh

echo "Compilando os módulos para o kernel atual"
akmods --force --kernels "$KERNEL_VERSION"

EOF

# Imagem principal
FROM quay.io/fedora/fedora-silverblue:44

RUN mkdir -p /var/roothome /data /var/home
# Copia lista de pacotes e módulos compilados
COPY pacotes_rpm ./
COPY --from=builder /var/cache/akmods/nvidia/kmod-nvidia*.rpm ./
COPY --from=builder /var/cache/akmods/xpadneo/kmod-xpadneo*.rpm ./

RUN <<EOF
echo "Ajustando diretórios para /usr/local e /opt para evitar problemas de permissão e facilitar a instalação dos pacotes"
rm -rf /opt
mkdir /var/opt
ln -s /var/opt /opt
mkdir /var/usrlocal
mv /usr/local /usr/local_old
ln -s /var/usrlocal /usr/local
mv /usr/local_old/* /usr/local/
rm -rf /usr/local_old
EOF

RUN <<EOF
echo "Baixa os repositórios dos drivers"
dnf5 copr enable sentry/xpadneo -y
dnf5 config-manager addrepo -y --from-repofile=https://negativo17.org/repos/fedora-uld.repo
dnf5 config-manager addrepo -y --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo
# Remove o gnome-software-rpm-ostree para evitar conflitos de dependências, já que ele não é necessário em uma imagem minimalista

echo "Remove PackageKit e RPM-OSTree da GNOME Software"
dnf5 remove -y gnome-software-rpm-ostree gnome-software-packagekit

echo "Atualiza imagem depois e todos os repos adicionados"
dnf5 upgrade -y --refresh
EOF

# Drivers via módulo ou firmware
RUN <<EOF

echo "Baixnado pacotes para o driver da NVIDIA"
dnf5 download nvidia-kmod-common nvidia-driver-cuda

echo "Instala pacotes sem puxar dependências para evitar conflitos"
rpm -vi --nodeps nvidia-kmod-common*.rpm
rpm -vi --nodeps nvidia-driver-cuda*.rpm

echo "Instala kmods já compilados"
dnf5 -y install ./kmod-nvidia-*.rpm
dnf5 -y install ./kmod-xpadneo-*.rpm

EOF

RUN <<EOF

echo "Instalando pacotes adicionais e essenciais"
tr '\n' ' ' < pacotes_rpm | xargs dnf5 install -y

EOF

RUN <<EOF

echo "Inicializando usuários do systemd"
systemd-sysusers && grpconv && pwconv
EOF

# Etapa de cópia para os parâmetros de boot
COPY 10-nvidia-args.toml 11-rhgb-quiet-args.toml ./

RUN <<EOF 

echo "Adicionando parâmetros de boot"
mv -v 10-nvidia-args.toml /usr/lib/bootc/kargs.d/10-nvidia-args.toml
mv -v 11-rhgb-quiet-args.toml /usr/lib/bootc/kargs.d/11-rhgb-quiet-args.toml

EOF

# Etapa de cópia para o Secure Boot
COPY .anchor/* ./
COPY postinstall/ /tmp/postinstall/

RUN <<EOF
set -e

bash /tmp/postinstall/sign-modules.sh
EOF

# Fase de limpeza
RUN <<EOF

echo "Removendo resquícios de tudo"
rm -rvf pacotes_rpm 
rm -rvf "kmod-*.rpm"
rm -rvf .anchor
rm -rvf /tmp/postinstall
dnf5 clean all
rm -rfv /var/cache/* \
        /var/lib/* \
        /var/log/* \
        /var/tmp/* 
EOF

# Verificar por erros na imagem 
RUN bootc container lint