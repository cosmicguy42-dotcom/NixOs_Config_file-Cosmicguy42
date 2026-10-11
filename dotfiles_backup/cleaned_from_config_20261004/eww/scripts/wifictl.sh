#!/usr/bin/env bash

if [[ -z $(eww active-windows | grep 'wifictl') ]]; then
    eww open wifictl && eww update wifictlrev=true
else
    eww update wifictlrev=false && eww update wificonfigrev=false
    (sleep 0.2 && eww close wifictl) &
fi
