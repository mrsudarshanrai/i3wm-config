#!/bin/bash

BATTERY_PATH=/sys/class/power_supply/BAT0

if [ ! -f "$BATTERY_PATH/capacity" ]; then
  echo "no battery found at $BATTERY_PATH, exiting"
  exit 0
fi

notified=""
while true; do
  battery_percentage=$(cat "$BATTERY_PATH/capacity")
  status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo Unknown)

  if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
    notified=""
  elif [ "$battery_percentage" -le 10 ] && [ "$notified" != "critical" ]; then
    notify-send -u critical "Battery running critically low: $battery_percentage%"
    notified="critical"
  elif [ "$battery_percentage" -le 15 ] && [ -z "$notified" ]; then
    notify-send "Battery running low: $battery_percentage%"
    notified="low"
  fi
  sleep 10
done
