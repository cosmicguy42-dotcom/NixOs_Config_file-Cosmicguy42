#!/usr/bin/env bash
# System summary for Settings > About, as JSON.
os=$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}")
cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//; s/([^)]*)//g; s/  */ /g')
gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | cut -d: -f3- | sed 's/^ *//; s/ (rev.*//')
mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.1f / %.1f GiB", (t-a)/1048576, t/1048576}' /proc/meminfo)
disk=$(df -h --output=used,size / | tail -1 | awk '{print $1 " / " $2}')
jq -n --arg os "$os" --arg host "$(cat /etc/hostname 2>/dev/null || uname -n)" --arg kernel "$(uname -r)" \
      --arg uptime "$(uptime -p | sed 's/^up //')" --arg cpu "$cpu" --arg gpu "$gpu" --arg mem "$mem" --arg disk "$disk" \
      --arg hypr "$(hyprctl version -j | jq -r .tag)" --arg qs "$(qs --version | head -1 | awk '{print $2}')" \
      --arg user "$USER" --arg shell "$(basename "$SHELL")" \
      '{os:$os, host:$host, kernel:$kernel, uptime:$uptime, cpu:$cpu, gpu:$gpu, memory:$mem, disk:$disk, hyprland:$hypr, quickshell:$qs, user:$user, shell:$shell}'
