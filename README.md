# DFRobot DFR0672 setup script

Setup and install script for the DFRobot Smart Cooling Hat (DFR0672) on Raspberry Pi.

## What it does
- Enables I2C
- Installs wiringPi (builds the official 3.16 package)
- Downloads the official DFRobot `temp_control` bundle
- Applies minimal patches for Debian 13 toolchain compatibility
- Builds fan + OLED binaries
- Installs a custom OLED page layout (CPU temp, CPU usage %, RAM usage %) with 5s rotation
- Installs an RGB service with selectable modes (temp-based or fixed RGB)
- Installs systemd services for fan and OLED

## Usage
```bash
chmod +x install.sh
./install.sh
```

Options:
- `./install.sh --fan` (fan only)
- `./install.sh --oled` (OLED only)

## Services
- `dfrobot-fan.service` - runs `fan_temp`
- `dfrobot-oled.service` - runs `oled`
- `dfrobot-rgb.service` - runs RGB via `/usr/local/bin/dfrobot-rgb`

## RGB control
Default is temperature-based color mapping. The installer patches `rgb.c` so fixed colors work with RGB arguments. Use the control helper on the Pi:
```bash
sudo dfrobot-rgbctl status
sudo dfrobot-rgbctl disable
sudo dfrobot-rgbctl enable
sudo dfrobot-rgbctl temp
sudo dfrobot-rgbctl fixed 255 64 0
sudo dfrobot-rgbctl rainbow
sudo dfrobot-rgbctl speed 0.5
sudo dfrobot-rgbctl interval 5
sudo dfrobot-rgbctl red
sudo dfrobot-rgbctl warmwhite
```

Preset colors:
`red`, `green`, `blue`, `cyan`, `purple`, `orange`, `white`, `warmwhite`, `pink`

Configuration file:
`/etc/dfrobot-rgb.conf`

Check status:
```bash
sudo systemctl status dfrobot-fan.service
sudo systemctl status dfrobot-oled.service
```

## Notes
- Tested on Debian 13 (trixie) on Raspberry Pi 4B.
- wiringPi is installed from source because it is not in Debian repos.
- OLED I2C should appear at `0x3c`, controller at `0x0d`.
- OLED pages rotate every 5 seconds in this setup.

## References
- DFRobot wiki: https://wiki.dfrobot.com/Smart_Cooling_Hat_For_Raspberry_Pi_4B_SKU_DFR0672
- wiringPi: https://github.com/WiringPi/WiringPi
