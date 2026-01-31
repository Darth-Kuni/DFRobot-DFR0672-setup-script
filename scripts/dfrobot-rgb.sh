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
FIXED_INTERVAL="${FIXED_INTERVAL:-5.0}"
RAINBOW_DELAY="${RAINBOW_DELAY:-1.0}"
WORKDIR="${WORKDIR:-/home/biqu/dfrobot_dfr0672/temp_control/temp_control}"

if [[ "$MODE" == "temp" ]]; then
  exec "$WORKDIR/rgb_temp"
elif [[ "$MODE" == "fixed" ]]; then
  while true; do
    "$WORKDIR/rgb" "$RGB_R" "$RGB_G" "$RGB_B"
    sleep "$FIXED_INTERVAL"
  done
elif [[ "$MODE" == "rainbow" ]]; then
  exec /usr/local/bin/dfrobot-rainbow "$WORKDIR" "$RAINBOW_DELAY"
else
  echo "invalid MODE=$MODE (use temp|fixed|rainbow)" >&2
  exit 1
fi
