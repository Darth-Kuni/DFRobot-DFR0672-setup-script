#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/dfrobot-rgb.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "missing $CONFIG_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

MODE="${MODE:-temp}"
RGB_R="${RGB_R:-255}"
RGB_G="${RGB_G:-255}"
RGB_B="${RGB_B:-255}"
WORKDIR="${WORKDIR:-/home/biqu/dfrobot_dfr0672/temp_control/temp_control}"

if [[ "$MODE" == "temp" ]]; then
  exec "$WORKDIR/rgb_temp"
elif [[ "$MODE" == "fixed" ]]; then
  exec "$WORKDIR/rgb" "$RGB_R" "$RGB_G" "$RGB_B"
else
  echo "invalid MODE=$MODE (use temp|fixed)" >&2
  exit 1
fi