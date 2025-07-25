#!/bin/bash

# When this script starts, the container is starting-up.
# On Android 10+ devices, we need to properly replicate APEX bind-mounts
# on the host system.

LXC_ROOTFS="/var/lib/lxc/android/rootfs"

info() {
        echo "I: $@"
}

warning() {
        echo "W: $@" >&2
}

error() {
        echo "E: $@" >&2
        exit 1
}

get_source_apex_name() {
        NAME="$(echo ${1} | sed -E 's|\.v[0-9]+$||g')"

        for choice in ${NAME} ${NAME}.release ${NAME}.debug ${NAME}.current; do
                if [ -e "/android/system/apex/${choice}" ]; then
                        echo "${choice}"
                        break
                fi
        done
}

# Get Android container version
ANDROID_SDK_VERSION=$(grep ro.build.version.sdk= ${LXC_ROOTFS}/system/build.prop | cut -d "=" -f2)
if [ $(getconf LONG_BIT) == 32 ]; then
        LIBDIR="lib"
else
        LIBDIR="lib64"
fi

# Wait for the container
lxc-wait -n android -t 10 -s "RUNNING"

if [ $ANDROID_SDK_VERSION -ge 29 ]; then
        # Android >= 10
        info "Detected Android 10+ container"

        # Wait for apex to show up
        HYBRIS_LD_LIBRARY_PATH="/android/system/apex/com.android.runtime/${LIBDIR}/bionic:/android/system/apex/com.android.runtime.release/${LIBDIR}/bionic:/android/system/apex/com.android.runtime.debug/${LIBDIR}/bionic:/android/system/${LIBDIR}" \
                /usr/bin/droid/waitforservice apexd.status ready

        info "apexd ready, replicating bind-mounts"
        for mpoint in /apex/*; do
                # TODO: Actually determine from where the directory has been bind-mounted
                # from, and support non-flattened apexes
                if [ ! -d "${mpoint}" ] || [[ ${mpoint} == /apex/*@* ]]; then
                        continue
                fi

                apex=$(basename ${mpoint})
                target="/apex/${apex}"

                source_apex=$(get_source_apex_name ${apex})

                if [ -z "${source_apex}" ]; then
                        warning "Unable to finx source apex for apex ${apex}"
                        continue
                fi

                source="/android/system/apex/${source_apex}"

                if [ -d "${source}" ]; then
                        info "Replicating bind-mount for apex ${apex}"
                        mount --bind ${source} ${target}
                fi
        done
fi

if [ "${ANDROID_SDK_VERSION}" -ge 30 ]; then
        # https://source.android.com/docs/core/architecture/vndk/linker-namespace#linker-namespace-creation
        info "Detected Android 11+ container, setting up linkerconfig"
        mount -t tmpfs android_linkerconfig /linkerconfig
        /system/bin/linkerconfig --target /linkerconfig
        sed -i '' -E \
                -e 's:([^a-zA-Z])/:\1/android/:g' \
                -e 's:android/android/:android/:g' \
                /linkerconfig/ld.config.txt
fi

# Notify systemd we're done
systemd-notify --ready --status="Container ready"

# Block on lxc-wait
lxc-wait -n android -s "STOPPED"
