# Imagem principal
FROM quay.io/fedora/fedora-bootc:43

RUN mkdir -p /var/roothome /data /var/home

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

# Instala um gnome completo
dnf5 install @gnome-desktop -y

# Instala a Gnome-software sem PackageKit
dnf5 remove gnome-software -y
dnf5 install gnome-software --setopt=install_weak_deps=False -y

# instala alguns pacotes para ter um funcionamento básico do sistema
dnf5 -y install uld kernel-modules-extra @networkmanager-submodules @multimedia xdg-utils \
evince-thumbnailer ffmpegthumbnailer compsize usbutils distrobox \
toolbox nautilus micro ptyxis langpacks-core-pt_BR \
flatpak wget tree git glycin-thumbnailer langpacks-fonts-pt podman \
langpacks-pt_BR bash-color-prompt tuned tuned-ppd fastfetch zram spice-vdagent \
plymouth plymouth-core-libs plymouth-graphics-libs plymouth-plugin-label \
plymouth-plugin-two-step plymouth-scripts plymouth-system-theme \
plymouth-theme-spinner
EOF

# Instala pacotes extras para funcionamento correto do sistema
RUN dnf5 install btrfs-assistant fastfetch libgda libgda-sqlite \
podman-compose uld -y
	
# Driver da NVIDIA e controle de Xbox
RUN <<EOF dnf5 install -y xorg-x11-drv-nvidia-cuda akmod-nvidia xpadneo
echo "rhgb quiet" > /usr/lib/bootc/kargs.d/99-plymouth.conf
echo "rd.driver.blacklist=nouveau,nova_core modprobe.blacklist=nouveau,nova_core" > /usr/lib/bootc/kargs.d/98-nvidia.conf
kversion=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -n 1) && \
    akmods --force --kernel "$kversion"
# Limpa o DNF depois das transações    
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