#!/bin/bash

# fetches kernel source and modules

DETECT_KERNEL=`uname -r`
DETECT_ARCH=`uname -a | awk '{print \$12}'`

KERNEL=${1-$DETECT_KERNEL}
ARCH=${2-$DETECT_ARCH}

if [ -e /lib/modules/$KERNEL ] ; then
	echo "Modules already exist, skipping"
	exit
fi

echo -n ">> Getting modules.. "

# handle 2.6.18 kernel
if [ $KERNEL = '2.6.18-xenU-ec2-v1.0' ] ; then
	MODHOST=http://ec2-downloads.s3.amazonaws.com/
	MODZIP=ec2-modules-2.6.18-xenU-$ARCH.tgz

	wget ${MODHOST}$MODZIP
	tar xzvf $MODZIP -C /
	ln -s /lib/modules/2.6.18-xenU /lib/modules/2.6.18-xenU-ec2-v1.0
fi

echo "done"
