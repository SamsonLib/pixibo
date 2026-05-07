#!/bin/bash

if ! id "xibo" &>/dev/null; then
    sudo useradd -m -s /bin/bash xibo
fi

sudo usermod -aG video,audio,input,render xibo

echo "Passwort fuer den Xibo User:"
sudo passwd xibo

sudo -u xibo mkdir -p /home/xibo/env

curl -fsSL https://dl.xiboplayer.org/deb/GPG-KEY.asc | sudo tee /usr/share/keyrings/xiboplayer.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/xiboplayer.asc] https://dl.xiboplayer.org/deb/debian/trixie ./" | sudo tee /etc/apt/sources.list.d/xiboplayer.list
sudo apt update && sudo apt install arexibo xinit unattended-upgrades x11-xserver-utils

read -p "Hostname (Display Name im xibo-cms, ssh Name): " HOSTNAME
sudo hostnamectl hostname "$HOSTNAME"
read -p "Xibo CMS Addr: " HOST
read -p "Xibo CMS Key: " KEY


sudo dpkg-reconfigure -plow unattended-upgrades

sudo -u xibo /usr/bin/arexibo --host "$HOST" --key "$KEY" /home/xibo/env

echo "Suthentifiziere das Display im xibo-cms"
read -p "Press enter to continue"

USER_NAME="xibo"
TTY="tty1"
CONF_DIR="/etc/systemd/system/getty@${TTY}.service.d"
CONF_FILE="${CONF_DIR}/autologin.conf"

sudo mkdir -p "$CONF_DIR"

sudo tee "$CONF_FILE" > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "Autologin enabled fuer '$USER_NAME', $TTY"

sudo tee "/home/xibo/.bash_profile" > /dev/null <<EOF
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/$TTY" ]; then
    exec startx
fi
EOF

sudo tee "/home/xibo/.xinitrc" > /dev/null <<EOF
#!/bin/sh
xset s off # Turns off the screensaver 
xset s noblank # Prevents screen blanking 
xset -dpms # Disables DPMS power management
exec /usr/bin/arexibo "/home/xibo/env"
EOF

sudo chmod +x "/home/xibo/.xinitrc"

sudo chown -R "$USER_NAME:$USER_NAME" "$HOME/.bash_profile" "$HOME/.xinitrc"

sudo systemcl enable ssh
sudo systemctl daemon-reexec
sudo systemctl restart getty@${TTY}.service
sudo systemctl daemon-reload
