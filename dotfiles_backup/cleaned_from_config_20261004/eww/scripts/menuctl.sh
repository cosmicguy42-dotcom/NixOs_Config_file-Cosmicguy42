#!/usr/bin/env bash

if [[ -z $(eww active-windows | grep 'menuctl') ]]; then
    eww open menuctl && eww update menurev=true
else
    eww update menurev=false
    (sleep 0.2 && eww close menuctl) &
fi
