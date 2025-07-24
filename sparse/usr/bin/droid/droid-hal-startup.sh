#!/bin/sh
cd /
touch /dev/.coldboot_done

export LD_LIBRARY_PATH=

# Save systemd notify socket name to let droid-init-done.sh pick it up later
echo $NOTIFY_SOCKET > /run/droid-hal/notify-socket-name

# Use exec nohup since systemd may send SIGHUP, but droid-hal-init doesn't
# handle it. This avoids having to modify android_system_core, which would
# require different handling for every different android version.
# exec nohup /sbin/droid-hal-init

# breaks LXC if mounted
if [ -d /sys/fs/cgroup/schedtune ]; then
    umount -l /sys/fs/cgroup/schedtune || true
fi
# mount binderfs if needed
if [ ! -e /dev/binder ]; then
    mkdir -p /dev/binderfs
    mount -t binder binder /dev/binderfs -o stats=global
    ln -s /dev/binderfs/*binder /dev
fi

mkdir -p /dev/__properties__
mkdir -p /dev/socket

if [ -f /usr/bin/droid/halium-setup-local.sh ]; then
    /bin/sh /usr/bin/droid/halium-setup-local.sh
fi

lxc-start -n android -- /init

exit 0
