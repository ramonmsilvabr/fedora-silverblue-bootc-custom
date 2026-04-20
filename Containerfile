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

# Habilita repos do RPM Fusion
dnf5 install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Habilita repos d<pre>
dnf5 install 'dnf5-command(copr)' -y
dnf5 install 'dnf5-command(config-manager)' -y

dnf5 copr enable sentry/xpadneo -y
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-uld.repo -y

# Instala um gnome completo
dnf5 install @gnome-desktop -y

# Instala a Gnome-software sem PackageKit
dnf5 remove gnome-software -y
dnf5 install gnome-software --setopt=install_weak_deps=False -y

# instala alguns pacotes para ter um funcionamento básico do sistema
dnf5 -y install @networkmanager-submodules @multimedia xdg-utils \
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
podman-compose uld xpadneo -y
	
# Instalação do driver e dependências de compilação
# O akmod disparará a compilação do módulo durante o 'build' da imagem
RUN dnf5 install -y \
    akmod-nvidia \
    xorg-x11-drv-nvidia-cuda \
    kernel-devel \
    kernel-headers 

# Garante que o akmods compile o driver antes de finalizar a imagem
RUN kversion=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -n 1) && \
    akmods --force --kernel "$kversion"

# Limpa o DNF depois das transações    
RUN dnf clean all

# Habilita alguns serviços
RUN <<ELF
systemctl enable zram-swap.service
systemctl enable spice-vdagentd.service
systemctl mask systemd-remount-fs.service
ELF

