#!/bin/bash

# builds a generic image from a stage3 tarball and portage snapshot

RELEASE="2008.0"
IMAGESIZE="5120"
PACKAGES="wget vim dev-util/git zip unzip screen openssh gentoolkit ruby"
PACKAGES="$PACKAGES net-misc/whois net-dns/bind-tools net-misc/telnet-bsd curl"

# fail on any error
set -e

# unmounts the image
# --------------------------
function unmount_image() {
	while (mount | grep -q /mnt/image-fs/dev); do
		umount -f /mnt/image-fs/dev
	done
	while (mount | grep -q /mnt/image-fs/proc); do
		umount -f /mnt/image-fs/proc
	done
	while (mount | grep -q /mnt/image-fs); do
		umount -f /mnt/image-fs
	done
}

# Cleans up any leftovers from a previous execution
# --------------------------
function cleanup() {
	if [[ -d /mnt/image-fs ]]; then
		echo -n ">> Removing /mnt/image-fs.. "
		unmount_image
		rmdir /mnt/image-fs
		echo "done"
	fi
}

# Mounts an image in /mnt/image-fs
# --------------------------
function mount_image() {
	if [ ! -f $1 ] ; then
		echo "first parameter must be an image to mount"
		exit 1
	fi

	echo -n ">> Mounting $1 in /mnt/image-fs.. "
	mkdir /mnt/image-fs
	mount -o loop $1 /mnt/image-fs > /dev/null
	echo "done"
}

# Builds an image filesystem, mounts it ready for configuration
# --------------------------
function build_image() {
	if [ ! -f $IMAGEFILE ] ; then
		echo ">> Creating $ARCH image"
		echo -n ">> Creating basic image (${IMAGESIZE}Mb).. "
		dd if=/dev/zero of=$IMAGEFILE bs=1M count=$IMAGESIZE > /dev/null 2>&1
		mke2fs -q -F -j $IMAGEFILE > /dev/null
		echo "done"
  fi

	mount_image $IMAGEFILE

	echo -n ">> Download stage3 and portage.. "
	curl -s "http://gentoo.osuosl.org/releases/x86/current/stages/stage3-$ARCH-$RELEASE.tar.bz2" -o "$FILE_STAGE3"
	curl -s http://gentoo.osuosl.org/snapshots/portage-latest.tar.bz2 -o "$FILE_PORTAGESNAPSHOT"
	echo "done"

	echo -n ">> Extracting stage3 and portage.. "
	OLDCWD=`pwd`
	cd /mnt/image-fs
	tar xjpf "$FILE_STAGE3"
	tar xjf "$FILE_PORTAGESNAPSHOT" -C /mnt/image-fs/usr
	cd $OLDCWD
	echo "done"
}

# Preconfigures the image by injecting files into its filesystem
# --------------------------
function preconfigure_image() {
	echo -n ">> Setting timezone to $TIMEZONE.. "
	cp -L /etc/localtime /mnt/image-fs/etc/localtime
	cp /usr/share/zoneinfo/$TIMEZONE /mnt/image-fs/etc/localtime
	echo "TIMEZONE=$TIMEZONE" > /mnt/image-fs/etc/conf.d/clock
	echo "done"

	echo -n ">> Injecting gentoo configuration files.. "
	cp -L /etc/resolv.conf /mnt/image-fs/etc/
	sed -i -e 's/^EDITOR/#EDITOR/' -e 's/^#\(EDITOR=.\+vim"\)$/\1/' /mnt/image-fs/etc/rc.conf
	sed -i -e 's/^USE="\(.\+\)"$/USE="\1 -gpm"/' /mnt/image-fs/etc/make.conf
	cp "$FILE_MAKECONF" /mnt/image-fs/etc/make.conf
	cp "$FILE_LOCALEGEN" /mnt/image-fs/etc/locale.gen
	echo "done"

	echo -n ">> Setting profile to $ARCH_KEYWORD.. "
	ln -fns ../usr/portage/profiles/default-linux/$ARCH_KEYWORD/2007.0 /mnt/image-fs/etc/make.profile
	echo "done"
}

# Chroots into the image, running this script with the configure_image target
# --------------------------
function chroot_image() {
	echo -n ">> Chrooting image.. "
	set +e
	mount -t proc none /mnt/image-fs/proc > /dev/null 2>&1
	mount -o bind /dev /mnt/image-fs/dev > /dev/null 2>&1
	set -e
	cp $FILE_SCRIPT /mnt/image-fs/root/configure.sh
	chroot /mnt/image-fs /bin/bash /root/configure.sh -c $1
}

# Operates inside the chroot, configures portage, etc
# --------------------------
function chroot_configure_image() {
	echo "done"
	env-update > /dev/null 2>&1
	source /etc/profile > /dev/null 2>&1

	echo -n ">> Generating locale.. "
	locale-gen > /dev/null 2>&1
	echo "done"

	echo -n ">> Installing system daemons.. "
	emerge -q -k syslog-ng vixie-cron dhcpcd
	rc-update add syslog-ng default > /dev/null
	rc-update add vixie-cron default > /dev/null

	echo -n ">> Configuring networking.. "
	echo 'config_eth0="dhcp"' >/etc/conf.d/net
	rc-update add net.eth0 default
	echo "done"

	echo -n ">> Tuning TCP settings.. "
	echo "net.core.rmem_max = 16777216" >>/etc/sysctl.conf
	echo "net.core.wmem_max = 16777216" >>/etc/sysctl.conf
	echo "net.ipv4.tcp_rmem = 4096 87380 16777216" >>/etc/sysctl.conf
	echo "net.ipv4.tcp_wmem = 4096 65536 16777216" >>/etc/sysctl.conf
	echo "net.ipv4.tcp_no_metrics_save = 1" >>/etc/sysctl.conf
	echo "net.ipv4.tcp_moderate_rcvbuf = 1" >>/etc/sysctl.conf
	echo "net.core.netdev_max_backlog = 2500" >>/etc/sysctl.conf
	sysctl -p
	echo "done"

	echo -n ">> Installing other packages.. "
	emerge -q -k $PACKAGES openssh ntp sudo
	rc-update add sshd default
	rc-update add ntpd default
	sed -i -e 's/^# \(%wheel\tALL=(ALL)\tALL\)$/\1/' /etc/sudoers
	echo "done"

	rm /root/configure.sh
}

# Updates an existing image's portage and world
# --------------------------
function chroot_update_image() {
	echo "done"
	echo -n ">> Updating portage and world.. "
	emerge -q --sync

	# crack lib has a problem with umerge-orphans that kills an emerge world
	FEATURES="-unmerge-orphans" emerge -u sys-libs/cracklib
	emerge -u portage

	# emerge everything else
	emerge -q --update --newuse --deep world
	echo "done"

	echo -n ">> Cleaning portage.. "
	emerge --depclean
	revdep-rebuild
	hash -r
	grpck
	grpconv
	eclean -d distfiles
	eclean -d packages

	rm /root/configure.sh
}

# Main execution block
# --------------------------

function usage() {
cat << EOF
Usage: $0 [options]

This script builds a generic gentoo stage3 image, without a kernel

OPTIONS:
   -h      Show this message
   -c      The operation to execute, defaults to all
   -i      The imagefile to provide to commands, generated by default
   -a      The arch, either x86 or x86_64
   -t      The timezone to use, default to GMT
   -v      Verbose
EOF
}

while getopts ":c:i:a:t:vh" OPTIONS; do
	case $OPTIONS in
		c ) COMMAND=$OPTARG;;
		i ) IMAGEFILE=$OPTARG;;
		a ) ARCH=$OPTARG;;
		t ) TIMEZONE=$OPTARG;;
		v ) VERBOSE=1;;
		? )
			usage
			exit
			;;
	esac
done

# run time configuration
COMMAND=${COMMAND-"all"}
ARCH=${ARCH-"x86"}
DEFAULTIMAGEFILE="gentoo-$ARCH-$(date +%Y%m%d)"
IMAGEFILE=${IMAGEFILE-$DEFAULTIMAGEFILE}
TIMEZONE=${TIMEZONE-"GMT"}

# determine either x86 or amd64
if [ "$ARCH" = 'x86_64' ] ; then
	ARCH_KEYWORD="amd64"
else
	ARCH_KEYWORD="x86"
fi

# file paths
FILE_SCRIPT=$(which $0)
FILE_BASEDIR=$(dirname $FILE_SCRIPT)
FILE_STAGE3="$FILE_BASEDIR/files/stage3-$ARCH-$RELEASE.tar.bz2"
FILE_PORTAGESNAPSHOT="$FILE_BASEDIR/files/portage-latest.tar.bz2"
FILE_MAKECONF="$FILE_BASEDIR/files/make.$ARCH.conf"
FILE_LOCALEGEN="$FILE_BASEDIR/files/locale.gen"

case "$COMMAND" in

	# builds just the .img file with stage3 and portage
	build)
		cleanup
		build_image
		cleanup
		exit
		;;

	# called with an image name, mounts and configures a stage3/portage image
	preconfigure)
		cleanup
		mount_image $IMAGEFILE
		preconfigure_image
		chroot_image chroot_configure_image
		exit
		;;

	# updates an image to a new version
	update)
		cleanup
		mount_image $IMAGEFILE
		chroot_image chroot_update_image
		exit
		;;

	# called within chroot, never directly
	chroot*)
		$COMMAND
		cleanup
		exit
		;;

	# builds the image, skips the update
	build_and_configure)
		cleanup
		build_image
		preconfigure_image
		chroot_image chroot_configure_image
		update_image
		;;

	# default task, cleans, builds, configures and finally updates the image
	all)
		cleanup
		build_image
		preconfigure_image
		chroot_image chroot_configure_image
		chroot_image chroot_update_image
		;;
esac
