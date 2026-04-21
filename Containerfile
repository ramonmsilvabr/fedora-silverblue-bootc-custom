# Imagem principal
FROM quay.io/fedora/fedora-bootc:44

RUN mkdir -p /var/roothome /data /var/home
# Copia lista de pacotes
COPY pacotes_rpm ./

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

# Habilita repos d
dnf5 install 'dnf5-command(config-manager)' -y
dnf5 install 'dnf5-command(copr)' -y
dnf5 copr enable sentry/xpadneo -y
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-uld.repo -y
dnf5 install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Instala um gnome completo
dnf5 install @gnome-desktop -y --exclude=gnome-software

# Instala a Gnome-software sem PackageKit
dnf5 install gnome-software --setopt=install_weak_deps=False -y

# instala alguns pacotes para ter um funcionamento básico do sistema
tr '\n' ' ' < pacotes_rpm | xargs dnf5 install -y
EOF

# Drivers via módulo ou firmware
RUN dnf5 install -y alsa-firmware alsa-sof-firmware \
xorg-x11-drv-nvidia-cuda akmod-nvidia-open \
xpadneo \
uld 

# Constrói os módulos
RUN kversion=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -n 1) && \
    akmods --force --kernel "$kversion"

# Limpa o systemd users para chegar corretamente
RUN systemd-sysusers && grpconv && pwconv

# Parâmetros de boot
COPY 10-nvidia-args.toml 11-rhgb-quiet-args.toml ./

RUN <<EOF mv -v 10-nvidia-args.toml /usr/lib/bootc/kargs.d/10-nvidia-args.toml
mv -v 11-rhgb-quiet-args.toml /usr/lib/bootc/kargs.d/11-rhgb-quiet-args.toml
plymouth-set-default-theme bgrt
EOF
 
# Fase de limpeza
RUN <<EOF    
rm -rvf pacotes_rpm 
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