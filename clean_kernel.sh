OLD=$(ls -tr /boot/vmlinuz-* | head -n -2 | cut -d- -f2- | awk '{print "linux-image-" $0}')
if [ -n "$OLD" ]; then sudo apt-get -q remove --purge $OLD; fi
