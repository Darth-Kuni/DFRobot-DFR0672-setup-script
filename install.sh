#!/usr/bin/env bash
set -euo pipefail

# DFRobot DFR0672 setup script for Raspberry Pi OS / Debian
# Installs wiringPi, enables I2C, builds DFRobot control binaries,
# and installs systemd services for fan and OLED stats.

ROLE="${1-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$ROLE" == "--help" || "$ROLE" == "-h" ]]; then
  echo "Usage: ./install.sh [--fan] [--oled] [--rgb]"
  echo "  --fan   install and enable fan_temp service"
  echo "  --oled  install and enable OLED stats service"
  echo "  --rgb   install and enable RGB service (temp or fixed)"
  exit 0
fi

INSTALL_FAN=1
INSTALL_OLED=1
INSTALL_RGB=1

if [[ "$ROLE" == "--fan" ]]; then
  INSTALL_OLED=0
  INSTALL_RGB=0
elif [[ "$ROLE" == "--oled" ]]; then
  INSTALL_FAN=0
  INSTALL_RGB=0
elif [[ "$ROLE" == "--rgb" ]]; then
  INSTALL_FAN=0
  INSTALL_OLED=0
fi

sudo apt-get update
sudo apt-get install -y git build-essential i2c-tools unzip

# Enable I2C (non-interactive)
if command -v raspi-config >/dev/null 2>&1; then
  sudo raspi-config nonint do_i2c 0 || true
fi
sudo modprobe i2c-dev || true

# Install wiringPi (build Debian package)
if ! command -v gpio >/dev/null 2>&1; then
  cd /tmp
  rm -rf WiringPi
  git clone https://github.com/WiringPi/WiringPi.git
  cd WiringPi
  ./build debian
  sudo dpkg -i /tmp/WiringPi/debian-template/wiringpi_*_arm64.deb
fi

# Fetch DFRobot temp_control zip
WORKDIR="$HOME/dfrobot_dfr0672"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

git clone https://github.com/OldWang-666/temp_control.git
cd temp_control
unzip -o temp_control.zip
cd temp_control

# Use custom OLED pages (CPU temp, CPU usage, RAM usage) with 5s rotation.
if [[ -f "$SCRIPT_DIR/oled.c" ]]; then
  cp "$SCRIPT_DIR/oled.c" "$WORKDIR/temp_control/temp_control/oled.c"
fi

# Patch for Debian 13 toolchain
if ! grep -q "#include <unistd.h>" fan_temp.c; then
  sed -i '7i #include <unistd.h>' fan_temp.c
fi
if ! grep -q "#include <unistd.h>" rgb_temp.c; then
  sed -i '7i #include <unistd.h>' rgb_temp.c
fi

# Fix swap_values -> ssd1306_swap for OLED
sed -i 's/swap_values/ssd1306_swap/g' ssd1306_i2c.c

# Build binaries
make_one() {
  local cmd="$1"
  echo "[build] $cmd"
  bash -lc "$cmd"
}

make_one "gcc -o fan fan.c -lwiringPi"
make_one "gcc -o fan_temp fan_temp.c -lwiringPi"
make_one "gcc -o rgb rgb.c -lwiringPi"
make_one "gcc -o rgb_temp rgb_temp.c -lwiringPi"
make_one "gcc -o oled oled.c ssd1306_i2c.c -lwiringPi"

# Install systemd services
if [[ $INSTALL_FAN -eq 1 ]]; then
  cat <<EOF | sudo tee /etc/systemd/system/dfrobot-fan.service >/dev/null
[Unit]
Description=DFRobot Smart Cooling Hat fan_temp
After=network-online.target

[Service]
WorkingDirectory=$WORKDIR/temp_control/temp_control
ExecStart=$WORKDIR/temp_control/temp_control/fan_temp
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now dfrobot-fan.service
fi

if [[ $INSTALL_OLED -eq 1 ]]; then
  cat <<EOF | sudo tee /etc/systemd/system/dfrobot-oled.service >/dev/null
[Unit]
Description=DFRobot Smart Cooling Hat OLED stats
After=network-online.target

[Service]
WorkingDirectory=$WORKDIR/temp_control/temp_control
ExecStart=$WORKDIR/temp_control/temp_control/oled
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now dfrobot-oled.service
fi

if [[ $INSTALL_RGB -eq 1 ]]; then
  sudo install -m 0755 "$SCRIPT_DIR/scripts/dfrobot-rgb.sh" /usr/local/bin/dfrobot-rgb
  sudo install -m 0755 "$SCRIPT_DIR/scripts/dfrobot-rgbctl" /usr/local/bin/dfrobot-rgbctl
  sudo install -m 0644 "$SCRIPT_DIR/dfrobot-rgb.conf" /etc/dfrobot-rgb.conf

  cat <<EOF | sudo tee /etc/systemd/system/dfrobot-rgb.service >/dev/null
[Unit]
Description=DFRobot Smart Cooling Hat RGB
After=network-online.target

[Service]
WorkingDirectory=$WORKDIR/temp_control/temp_control
ExecStart=/usr/local/bin/dfrobot-rgb
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now dfrobot-rgb.service
fi

echo "Done."
