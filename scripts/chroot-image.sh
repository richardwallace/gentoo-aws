#!/bin/bash

mount -o loop $1 /mnt/image-fs > /dev/null
mount -t proc none /mnt/image-fs/proc > /dev/null 2>&1
mount -o bind /dev /mnt/image-fs/dev > /dev/null 2>&1

chroot /mnt/image-fs /bin/bash

umount /mnt/image-fs/{dev,proc}
umount /mnt/image-fs
