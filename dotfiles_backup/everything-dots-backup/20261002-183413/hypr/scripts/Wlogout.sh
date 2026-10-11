#!/usr/bin/env bash

if pgrep -x "wlogout" >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

wlogout -l "$HOME/.config/wlogout/layout" -C "$HOME/.config/wlogout/style.css"
