#!/bin/sh

while [ "$(/usr/bin/getprop vendor.service.nvram_init)" != "Ready" ]; do
    sleep 1
done

FILE=/mnt/vendor/nvdata/APCFG/APRDEB/BT_Addr
if [ -f "$FILE" ]; then
    hexdump -s 0 -n 6 -ve '/1 "%02X:"' $FILE | sed "s/:$//g" > /var/lib/bluetooth/board-address
else
    hexdump -s 0 -n 6 -ve '/1 "%02X:"' /vendor/nvdata/APCFG/APRDEB/BT_Addr | sed "s/:$//g" > /var/lib/bluetooth/board-address
fi
