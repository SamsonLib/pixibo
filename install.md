## 0. Install Setup
- Nenne den Benutzer ambesten root oder admin oder etwas anderes hauptsache nicht xibo

## 1. Erstellen vom Xibo Benutzer

```bash
sudo adduser xibo
sudo usermod -aG video,audio,input,render xibo
```
---

## 2. Env dir

```bash
sudo -u xibo mkdir -p /home/xibo/env
```

---

## 3. Install Arexibo
```bash
curl -fsSL https://dl.xiboplayer.org/deb/GPG-KEY.asc | sudo tee /usr/share/keyrings/xiboplayer.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/xiboplayer.asc] https://dl.xiboplayer.org/deb/debian/trixie ./" | sudo tee /etc/apt/sources.list.d/xiboplayer.list
sudo apt update && sudo apt install arexibo
```

---

## 4. Erster run, schreibt zugangsdaten in eine datei. Kann immer wieder verwaendet werden um adressen und keys zu aendern. 

- Display Name kann in "" angegeben werden, dann koennen leerzeichen verwaendet werden.

```bash
sudo hostnamectl hostname displayname
sudo -u xibo /usr/bin/arexibo --host "HOST" --key "KEY" /home/xibo/env
```
---

## 4.1 Autoupdates
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```
---

## 5. Autologin

```bash
#!/bin/bash

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

sudo systemctl daemon-reexec

sudo systemctl restart getty@${TTY}.service

echo "Autologin enabled for '$USER_NAME' on $TTY"
```

---

## 6. Autostart
```bash
#!/bin/bash

cat > "/home/xibo/.bash_profile" <<EOF
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/$TTY" ]; then
    exec startx
fi
EOF

sudo apt install x11-xserver-utils

cat > "/home/xibo/.xinitrc" <<EOF
#!/bin/sh
xset s off # Turns off the screensaver 
xset s noblank # Prevents screen blanking 
xset -dpms # Disables DPMS power management
exec /usr/bin/arexibo "/home/xibo/env"
EOF

chmod +x "/home/xibo/.xinitrc"

sudo chown -R "$USER_NAME:$USER_NAME" "$HOME/.bash_profile" "$HOME/.xinitrc"

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```
