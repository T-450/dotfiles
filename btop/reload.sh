#!/usr/bin/env bash
# btop/reload.sh: open btops re-read btop.conf and with it the re-rendered mango.theme (SIGUSR2; run by `theme set`)
pkill -USR2 -x btop || true
