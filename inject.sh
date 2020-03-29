#!/bin/sh

set -eu

EXECFILE=/usr/bin/nukedown
INSTALLDEST=/opt
#URL=https://openbsd.mirror.garr.it/pub/OpenBSD/6.6/amd64/install66.fs
URL=/root/target.img

# Install busybox and kexec
DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y kexec-tools busybox-static

# Check root disk
ROOTLABEL=$(cat /proc/cmdline | sed 's/.*\(root=[^ ]*\).*/\1/')
# Get running kernel and initrd
INITRD=/boot/initrd.img-$(uname -r)
VMLINUX=/boot/vmlinuz-$(uname -r)

# Add executor to ramdisk
cat <<_END_ >$EXECFILE
#!/bin/sh
/bin/echo "[+] running init script!"
/bin/echo "[ ] Let s nuke down the system"
/bin/mount -t tmpfs none /mnt
/bin/mkdir /mnt/proc
/bin/mkdir /mnt/dev
/bin/mkdir /mnt/sys
/bin/mkdir /mnt/run
/bin/mkdir /mnt/bin
/bin/mkdir /mnt/old_root
/bin/mkdir /mnt/$INSTALLDEST
/bin/cp $(which busybox) /mnt/bin
/bin/cp $INSTALLDEST/target.img /mnt/$INSTALLDEST
/bin/mount --move /proc /mnt/proc
/bin/mount --move /dev /mnt/dev
/bin/mount --move /sys /mnt/sys
/bin/mount --move /run /mnt/run
/sbin/pivot_root /mnt /mnt/old_root
echo "[ ] Overwriting disk..."
/bin/busybox dd if=$INSTALLDEST/target.img of=/dev/sda
/bin/busybox reboot -f
_END_
chmod +x $EXECFILE

#wget -O "$INSTALLDEST/target.img" "$URL"
cp "$URL" "$INSTALLDEST/target.img"

# Execute the new kernel
kexec -l --command-line="$ROOTLABEL nomodeset init=$EXECFILE" \
	--initrd="$INITRD" \
	-- "$VMLINUX"
systemctl kexec
