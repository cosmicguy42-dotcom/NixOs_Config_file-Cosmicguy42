#!/usr/bin/env bash

if [[ -z $(eww active-windows | grep 'calendar') ]]; then
    eww open calendar && eww update calrev=true
else
    eww update calrev=false
    (sleep 0.2 && eww close calendar) &
fi
