#!/bin/bash
if [ -e "/dev/wmtWifi" ]; then
	echo 1 > /dev/wmtWifi
fi
