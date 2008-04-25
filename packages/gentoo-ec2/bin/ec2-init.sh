#!/bin/bash

source /etc/conf.d/ec2
BINDIR=${BINDIR-/usr/local/bin}

# initialize all ec2 data

$BINDIR/ec2-get-metadata.sh
$BINDIR/ec2-import-sshkeys.sh
$BINDIR/ec2-import-sshkeys.sh
$BINDIR/ec2-get-modules.sh
