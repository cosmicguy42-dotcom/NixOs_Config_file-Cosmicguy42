#!/usr/bin/env bash

names=(
  "LibreWolf"
  "Zen Browser"
  "Ghostty"
  "Spotify"
  "VSCodium"
  "Neovim"
  "Dolphin"
  "Btop"
)

execs=(
  "librewolf"
  "zen"
  "ghostty"
  "spotify"
  "codium"
  "nvim"
  "dolphin"
  "btop"
)

icons=(
  "/home/kmv22/.local/share/icons/librewolf.png"
  "/home/kmv22/.local/share/icons/zen.png"
  "/home/kmv22/.local/share/icons/ghostty.png"
  "/home/kmv22/.local/share/icons/spotify.png"
  "/home/kmv22/.local/share/icons/vscodium.png"
  "/home/kmv22/.local/share/icons/nvim.png"
  "/home/kmv22/.local/share/icons/dolphin.png"
  "/home/kmv22/.local/share/icons/btop.png"
)

terminal=(
  false
  false
  false
  false
  false
  true
  false
  true
)

json="["

for i in "${!names[@]}"; do
  [[ $i -ne 0 ]] && json+=","
  json+="{\"name\":\"${names[$i]}\",\"exec\":\"${execs[$i]}\",\"icon\":\"${icons[$i]}\",\"terminal\":${terminal[$i]}}"
done

json+="]"
echo "$json"
