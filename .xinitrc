#!/bin/sh

[ -f "$HOME/.xprofile" ] && . "$HOME/.xprofile"

dwmblocks &
exec dwm
