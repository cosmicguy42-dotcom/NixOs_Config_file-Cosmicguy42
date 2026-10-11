#!/usr/bin/env bash

eww update keyhov=true
(sleep 0.45 && eww update keyrev="$(eww get keyhov)") &
