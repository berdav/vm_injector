#!/bin/sh

set -eu

EXECFILE=/usr/bin/nukedown
INSTALLDEST=/opt

URL=/root/target.img
OVA_URL=/root/target.ova
VMDK_URL=/root/target.vmdk

convert_vmdk() {
	VMDK="$1"
	DEBIAN_FRONTEND=noninteractive apt install -y qemu-utils
	qemu-img convert "$VMDK" "$URL"

	rm "$VMDK"
}

convert_ova() {
	OVA_URL="$1"
	# Check if the target is ova and convert it
	TARGET_TAR=$(echo "$OVA_URL" | sed 's/\.ova/.tar/')

	mv $OVA_URL $TARGET_TAR
	VMDK="$(tar taf $OVA_URL | grep vmdk)"

	tar xvaf "$TARGET_URL"

	convert_vmdk "$VMDK"

	rm 
}

# Install busybox and kexec
DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y kexec-tools busybox-static

if [ -f $VMDK_URL ]; then
	convert_vmdk "$VMDK_URL"
fi

if [ -f $OVA_URL ]; then
	convert_ova "$OVA_URL"
fi

# Check root disk
ROOTLABEL=$(cat /proc/cmdline | sed 's/.*\(root=[^ ]*\).*/\1/')
# Get running kernel and initrd
INITRD=/boot/initrd.img-$(uname -r)
VMLINUX=/boot/vmlinuz-$(uname -r)

TARGETDISK="$(mount  | grep ' / ' | awk '{print $1}' | sed 's/[0-9]*$//')"

# Add executor to ramdisk
cat <<_END_ >$EXECFILE
#!/bin/sh
/bin/echo "[+] running init script!"
/bin/echo "[ ] Let s nuke down the system"
/bin/mount -t tmpfs -o size=2G none /mnt
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
echo "[ ] Overwriting disk $TARGETDISK..."
/bin/busybox dd if=$INSTALLDEST/target.img of=$TARGETDISK conv=sync
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
