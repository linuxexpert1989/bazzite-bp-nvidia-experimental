# vim: set ft=make :

# Install LACT for overclocking & undervolting AMD GPUs
install-lact:
    #!/usr/bin/bash
    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < $IMAGE_INFO)
    ublue-update --wait
    if [[ ${BASE_IMAGE_NAME} == 'silverblue' ]]; then
        echo 'Installing LACT Libadwaita...'
        wget \
          $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
          jq -r ".assets[] | select(.name | test(\"lact-libadwaita.*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
          -O /tmp/lact.rpm
    else
        echo 'Installing LACT...'
        wget \
          $(curl -s https://api.github.com/repos/ilya-zlobintsev/LACT/releases/latest | \
          jq -r ".assets[] | select(.name | test(\"lact-[0-9].*fedora-$(rpm -E %fedora)\")) | .browser_download_url") \
          -O /tmp/lact.rpm
    fi
    rpm-ostree install --apply-live -y /tmp/lact.rpm
    sudo systemctl enable --now lactd
    rm /tmp/lact.rpm
    echo 'Complete.'

alias get-steamcmd := install-steamcmd

# Install SteamCMD (https://developer.valvesoftware.com/wiki/SteamCMD)
install-steamcmd:
    echo 'Installing SteamCMD...'
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -O /tmp/steamcmd.tar.gz
    mkdir -p ~/.steam
    tar -xvzf /tmp/steamcmd.tar.gz -C ~/.steam
    rm /tmp/steamcmd.tar.gz

# Install OpenRazer for Razer gaming hardware
install-openrazer:
    sudo wget https://download.opensuse.org/repositories/hardware:/razer/Fedora_$(rpm -E %fedora)/hardware:razer.repo -O /etc/yum.repos.d/hardware:razer.repo && \
    ublue-update --wait && \
    rpm-ostree install -y openrazer-meta razergenie && \
    if ! grep -q "plugdev" /etc/group; then \
      sudo bash -c 'grep "plugdev" /lib/group >> /etc/group' \
    ; fi && \
    sudo usermod -a -G plugdev $USER && \
    echo "Please reboot to apply needed changes."

alias get-wootility := install-wootility

# Install Wootility for configuring Wooting Keyboards
install-wootility:
    #!/usr/bin/bash
    if grep -q 'it.mijorus.gearlever' <<< $(flatpak list); then
      wget "https://api.wooting.io/public/wootility/download?os=linux&branch=lekker" -O $HOME/Downloads/wootility.AppImage
      flatpak run it.mijorus.gearlever $HOME/Downloads/wootility.AppImage
    else
      wget "https://api.wooting.io/public/wootility/download?os=linux&branch=lekker" -O $HOME/Desktop/wootility.AppImage
      chmod +x $HOME/Desktop/wootility.AppImage
    fi

# Install Adwaita-for-Steam theme for CSS Loader (https://github.com/tkashkin/Adwaita-for-Steam)
install-adwaita-for-steam:
    #!/usr/bin/bash
    if [ -d "$HOME/homebrew/themes" ]; then
        rm -rf "$HOME/homebrew/themes/Adwaita-for-Steam"
        git clone https://github.com/tkashkin/Adwaita-for-Steam.git --single-branch "$HOME/homebrew/themes/Adwaita-for-Steam"
    else
        echo 'Please install Decky Loader by running "ujust setup-decky install" first, then install CSS Loader from the Decky Plugin Store.'
    fi

# Install Oversteer for Logitech steering wheels
install-oversteer: distrobox-check-fedora
    distrobox enter -n fedora -- bash -c 'sudo dnf copr enable -y kylegospo/oversteer && \
      sudo dnf install -y oversteer && \
      distrobox-export --app oversteer'

# Install Solaar for Logitech Mice, Keyboards, and Trackpads
install-solaar: distrobox-check-fedora
    distrobox-enter -n fedora -- bash -c 'sudo dnf install -y \
      solaar && \
      distrobox-export --app solaar' && \
    mkdir -p ~/.config/autostart && \
    rm -f ~/.config/autostart/fedora-solaar.desktop && \
    cp ~/.local/share/applications/fedora-solaar.desktop ~/.config/autostart/fedora-solaar.desktop

# Install Resilio Sync, a file synchronization utility powered by BitTorrent
install-resilio-sync: distrobox-check-fedora
    distrobox-enter -n fedora -- 'sudo rpm --import https://linux-packages.resilio.com/resilio-sync/key.asc' && \
    distrobox-enter -n fedora -- 'sudo wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/resilio_sync/resilio-sync.repo -O /etc/yum.repos.d/resilio-sync.repo' && \
    distrobox-enter -n fedora -- 'sudo dnf install -y resilio-sync' && \
    mkdir -p ~/.config/systemd/user/ && \
    rm -f ~/.config/systemd/user/fedora-resilio-sync.service && \
    wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/resilio_sync/fedora-resilio-sync.service -O ~/.config/systemd/user/fedora-resilio-sync.service && \
    systemctl --user daemon-reload && \
    systemctl enable --user --now fedora-resilio-sync.service

# Install scrcpy, a utility that mirrors Android devices (video and audio) connected via USB or over TCP/IP
install-scrcpy: distrobox-check-fedora
    distrobox enter -n fedora -- bash -c 'sudo dnf copr enable -y zeno/scrcpy && \
      sudo dnf install -y scrcpy && \
      distrobox-export --app scrcpy'

# Install OpenTabletDriver, an open source, cross-platform, user-mode tablet driver
install-opentabletdriver:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    if grep -qvz "arch" <<< $(distrobox list); then \
      Assemble noconfirmcreate "" "arch"; \
    fi && \
    distrobox enter -n arch -- ' paru -S opentabletdriver --noconfirm' && \
    mkdir -p ~/.config/systemd/user/ && \
    rm -f ~/.config/systemd/user/arch-opentabletdriver.service && \
    wget https://raw.githubusercontent.com/ublue-os/bazzite/main/post_install_files/OpenTabletDriver/opentabletdriver.service -O ~/.config/systemd/user/arch-opentabletdriver.service && \
    systemctl --user daemon-reload && \
    systemctl enable --user --now arch-opentabletdriver.service && \
    distrobox enter -n arch -- 'distrobox-export --app otd-gui'

# Create fedora distrobox if it doesn't exist
[private]
distrobox-check-fedora:
    #!/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if grep -qvz "fedora" <<< $(distrobox list); then
      echo "Setting up Fedora distrobox"
      Assemble noconfirmcreate "" "fedora"
    fi