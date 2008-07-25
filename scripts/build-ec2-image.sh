#!/bin/bash

# builds a ec2 image from a stage3 image, passed as the first param

PACKAGES="ec2-ami-tools ec2-api-tools gentoo-ec2"

# unmounts the image
# --------------------------
function unmount_image() {
	mount | grep -q /mnt/image-fs/dev && umount -f /mnt/image-fs/dev
	mount | grep -q /mnt/image-fs/proc && umount -f /mnt/image-fs/proc
	mount | grep -q /mnt/image-fs && umount -f /mnt/image-fs
}

# clean up from previous attempts
# --------------------------
function cleanup() {
	if [[ -d /mnt/image-fs ]]; then
	echo -n ">> Removing /mnt/image-fs.. "
	mount | grep -q /mnt/image-fs/dev && umount -f /mnt/image-fs/dev
	mount | grep -q /mnt/image-fs/proc && umount -f /mnt/image-fs/proc
	mount | grep -q /mnt/image-fs && umount -f /mnt/image-fs
	rm -rf /mnt/image-fs
	echo "done"
	fi
}

# mount the image
# --------------------------
function mount_image() {
	echo -n ">> Mounting $1.. "
	mkdir /mnt/image-fs
	mount -o loop $1 /mnt/image-fs > /dev/null
	echo "done"
}

# inject ec2 specific settings
# --------------------------
function inject_ec2_config() {
	echo -n ">> Injecting ec2 configuration.. "
	cat $FILE_FSTAB > /mnt/image-fs/etc/fstab
	cat $FILE_MAKECONF > /mnt/image-fs/etc/make.conf
	cat $FILE_LOCALSTART > /mnt/image-fs/etc/conf.d/local.start
	mkdir -p /mnt/image-fs/etc/portage
	cat $FILE_RSYNCEXCLUDE > /mnt/image-fs/etc/portage/rsync_excludes
	cat $FILE_SSHDCONFIG > /mnt/image-fs/etc/ssh/sshd_config
	echo "done"
}

# Thin the image down
# --------------------------
function thin_image() {
	if [[ -d /mnt/image-fs/usr/portage ]]; then
	echo -n ">> Purging unneeded files.. "
	cd /mnt/image-fs/usr/portage
	rm -rf a* dev-* g* k* m* n* perl-* r* sci-* sec-* sys-* w* x*
	rm -rf /mnt/image-fs/usr/portage/distfiles/*
	echo "done"
	fi
}

# Chroots into the image, executes a particular command
# --------------------------
function chroot_image() {
	echo -n ">> Chrooting image.. "
	set +e
	mount -t proc none /mnt/image-fs/proc > /dev/null 2>&1
	mount -o bind /dev /mnt/image-fs/dev > /dev/null 2>&1
	set -e
	cp $FILE_SCRIPT /mnt/image-fs/root/configure.sh
	chroot /mnt/image-fs /bin/bash /root/configure.sh -c $1 -i $IMAGEFILE
}

# Operates inside the chroot, installs ec2 packages
# --------------------------
function chroot_ec2_ebuilds() {
	echo "done"
	env-update > /dev/null 2>&1
	source /etc/profile > /dev/null 2>&1

	echo -n ">> Installing gentoo-aws overlay.. "
	echo 'PORTDIR_OVERLAY=/usr/local/gentoo-aws' >> /etc/make.conf
	git clone git://github.com/dkubb/gentoo-aws.git
	mv -f gentoo-aws/overlay /usr/local/gentoo-aws
	rm -rf gentoo-aws/
	echo "done"

	echo -n ">> Installing ec2 tools.. "
	emerge -q -k $PACKAGES dev-ruby/rubygems
	echo "done"

	echo -n ">> Installing ruby gems.. "
	mkdir -p /tmp/updates
	curl -o /tmp/updates/s3sync.gem http://s3.amazonaws.com/rightscale_software/s3sync-1.1.4.gem
	gem install /tmp/updates/s3sync.gem
	echo "done"

	echo -n ">> Configuring kernel and modules.. "
	emerge -q -k ec2-sources
	ec2-get-modules.sh 2.6.18-xenU-ec2-v1.0 $ARCH
	echo 'loop' >>/etc/modules.autoload.d/kernel-2.6
	echo 'fuse' >>/etc/modules.autoload.d/kernel-2.6
	echo 'dm_mod' >>/etc/modules.autoload.d/kernel-2.6
	emerge -q -k ec2-sources sys-fs/lvm2 sys-fs/fuse
	echo "done"

	echo -n ">> Installing puppet.. "
	echo "app-admin/puppet" >> /etc/portage/package.keywords
	echo "dev-ruby/facter" >> /etc/portage/package.keywords
	emerge -q -k app-admin/puppet
	echo "done"

	rm -rf /tmp/updates
	rm /root/configure.sh
}

# Main execution block
# --------------------------

function usage() {
cat << EOF
Usage: $0 -i imagefile [options]

This script adds ec2 specific configuration to a generic gentoo stage3 image

OPTIONS:
   -h      Show this message
   -c      The operation to execute, defaults to all
   -i      The imagefile to provide to commands
   -v      Verbose
EOF
}

while getopts ":c:a:i:vh" OPTIONS; do
	case $OPTIONS in
		c ) COMMAND=$OPTARG;;
		a ) ARCH=$OPTARG;;
		i ) IMAGEFILE=$OPTARG;;
		? )
			usage
			exit
			;;
	esac
done

# run time configuration
COMMAND=${COMMAND-"all"}
ARCH=${ARCH-"x86"}

# valid parameters
if [ -z "$IMAGEFILE" ] ; then
	echo "Must provide a valid image file with -i"
	exit 1
fi

# file paths
FILE_SCRIPT=$(which $0)
FILE_BASEDIR=$(dirname $FILE_SCRIPT)
FILE_FSTAB="$FILE_BASEDIR/files/ec2/fstab"
FILE_MAKECONF="$FILE_BASEDIR/files/ec2/make.$ARCH.conf"
FILE_LOCALSTART="$FILE_BASEDIR/files/ec2/local.start"
FILE_RSYNCEXCLUDE="$FILE_BASEDIR/files/ec2/portage.rsync_exclude"
FILE_SSHDCONFIG="$FILE_BASEDIR/files/ec2/sshd_config"

# fail on any error
set -e

case "$COMMAND" in

	# called within chroot, never directly
	chroot*)
		$COMMAND
		cleanup
		exit
		;;

	# default task
	all)
		cleanup
		mount_image $IMAGEFILE
		inject_ec2_config
		chroot_image chroot_ec2_ebuilds
		thin_image
		unmount_image
		;;
esac
