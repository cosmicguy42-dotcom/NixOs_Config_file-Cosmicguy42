#!/usr/bin/env bash

if [[ -z $(eww active-windows | grep 'usrctl') ]]; then
    eww open usrctl && eww update ctlrev=true
else
    eww update ctlrev=false
    (sleep 0.2 && eww close usrctl) &
fi
