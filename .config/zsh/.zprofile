# Start X on tty1 only
if [[ -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
  exec startx
fi
