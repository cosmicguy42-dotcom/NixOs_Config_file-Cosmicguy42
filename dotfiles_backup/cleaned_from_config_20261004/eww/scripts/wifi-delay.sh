#!/usr/bin/env bash

eww update wifihov=true
(sleep 0.45 && eww update wifirev="$(eww get wifihov)") &
