#!/bin/bash

while true; do

  battery_percentage=$(cat /sys/class/power_supply/BAT0/capacity)
  if [ $battery_percentage -le 10 ]; then
    notify-send "Battery running critically low: $battery_percentage"
  elif [ $battery_percentage -le 15 ]; then
    notify-send "Battery running low: $battery_percentage"
  fi
  sleep 10
done
