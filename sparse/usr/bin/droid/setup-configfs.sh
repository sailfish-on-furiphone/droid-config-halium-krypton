#!/bin/sh

#Set up configfs as we are not using droid-boot init-script

GADGET_DIR=/sys/kernel/config/usb_gadget

# Sugar for accessing usb config
write() {
  echo -n "$2" > "$1"
}

mkdir $GADGET_DIR/g1
write $GADGET_DIR/g1/idVendor                   "0x18D1"
write $GADGET_DIR/g1/idProduct                  "0xD001"
mkdir $GADGET_DIR/g1/strings/0x409
write $GADGET_DIR/g1/strings/0x409/serialnumber "$1"
write $GADGET_DIR/g1/strings/0x409/manufacturer "Halium"
write $GADGET_DIR/g1/strings/0x409/product      "Halium Device"

mkdir $GADGET_DIR/g1/configs/b.1
mkdir $GADGET_DIR/g1/configs/b.1/strings/0x409
