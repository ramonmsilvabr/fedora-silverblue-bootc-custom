FROM quay.io/fedora/fedora-bootc:44 AS builder

RUN <<EOF
mkdir -p /etc/pki/akmods/private/ /etc/pki/akmods/certs/
rm -rvf /etc/pki/akmods/private/* /etc/pki/akmods/certs/*
EOF
COPY .anchor/secure_boot.key /etc/pki/akmods/private/akmods.key
COPY .anchor/secure_boot.der /etc/pki/akmods/certs/akmods.der
RUN <<ELL 
set -e
# Atualiza Kernel apenas
chmod 444 /etc/pki/akmods/certs/akmods.der
openssl pkcs8 -in /etc/pki/akmods/private/akmods.key -topk8 -nocrypt -out /etc/pki/akmods/private/akmods.key
chmod 400 /etc/pki/akmods/private/akmods.key
ln -s /etc/pki/akmods/certs/akmods.der /etc/pki/akmods/certs/public_key.der
ln -s /etc/pki/akmods/private/akmods.key /etc/pki/akmods/private/private_key.priv 
dnf5 upgrade -y 'kernel*' --refresh
# Instala ferramentas de desenvolvimento apenas
dnf5 -y install kernel-devel openssl perl-devel mokutil keyutils --refresh
# Variável para ter a versão do kernel atual
KERNEL_VERSION="$(rpm -q kernel-core --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
# Habilita repos no DNF e baixa os repositórios do xpadneo, uld e da NVIDIA
dnf5 install 'dnf5-command(config-manager)' -y
dnf5 install 'dnf5-command(copr)' -y
dnf5 copr enable sentry/xpadneo -y
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo
# Instala pacotes de desenvolvimento e drivers para compilar os módulos do kernel
dnf5 install -y nvidia-driver nvidia-open nvidia-driver-cuda xpadneo --refresh
akmods --force --kernels "$KERNEL_VERSION"
# Remove a chave privada para não deixar rastros    
rm /etc/pki/akmods/private/*
ELL

# Imagem principal
FROM quay.io/fedora/fedora-silverblue:44

RUN mkdir -p /var/roothome /data /var/home
# Copia lista de pacotes e módulos compilados
COPY pacotes_rpm ./
COPY --from=builder /var/cache/akmods/nvidia/kmod-nvidia*.rpm ./
COPY --from=builder /var/cache/akmods/xpadneo/kmod-xpadneo*.rpm ./

RUN <<EOF
# ajusta os links para opt e /usr/local ser gravável
rm -rf /opt
mkdir /var/opt
ln -s /var/opt /opt
mkdir /var/usrlocal
mv /usr/local /usr/local_old
ln -s /var/usrlocal /usr/local
mv /usr/local_old/* /usr/local/
rm -rf /usr/local_old


# Baixa os repositórios do xpadneo, uld e da NVIDIA
dnf5 copr enable sentry/xpadneo -y
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-uld.repo -y
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo

# Atualiza imagem depois e todos os repos adicionados
dnf5 -y upgrade --refresh
EOF

# Drivers via módulo ou firmware
RUN <<EOF
set -e 
# Apenas baixa esses dois pacotes
dnf5 download nvidia-kmod-common nvidia-driver-cuda

# Instala ambos sem dependências
rpm -vi --nodeps nvidia-kmod-common*.rpm
rpm -vi --nodeps nvidia-driver-cuda*.rpm

# Instala módulos compilados
dnf5 -y install ./kmod-nvidia-*.rpm
dnf5 -y install ./kmod-xpadneo-*.rpm

EOF

RUN tr '\n' ' ' < pacotes_rpm | xargs dnf5 install -y
# Limpa o systemd users para chegar corretamente
RUN systemd-sysusers && grpconv && pwconv

# Parâmetros de boot
COPY 10-nvidia-args.toml 11-rhgb-quiet-args.toml ./

RUN <<EOF mv -v 10-nvidia-args.toml /usr/lib/bootc/kargs.d/10-nvidia-args.toml
mv -v 11-rhgb-quiet-args.toml /usr/lib/bootc/kargs.d/11-rhgb-quiet-args.toml
EOF
 
# Fase de limpeza
RUN <<EOF    
rm -rvf pacotes_rpm 
rm -rvf "kmod-*.rpm"
dnf5 clean all
rm -rfv /var/cache/* \
        /var/lib/* \
        /var/log/* \
        /var/tmp/* 
EOF
# Habilita alguns serviços
RUN <<ELF
systemctl enable zram-swap.service
systemctl enable spice-vdagentd.service
systemctl mask systemd-remount-fs.service
ELF

# Verificar por erros na imagem 
RUN bootc container lint