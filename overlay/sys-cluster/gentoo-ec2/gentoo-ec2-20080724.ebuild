# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils git

DESCRIPTION="A set of scripts for running a gentoo ec2 instance"
HOMEPAGE="http://code.google.com/p/gentoo-aws"

EGIT_REPO_URI="git://github.com/dkubb/gentoo-aws.git"
EGIT_PROJECT="gentoo-ec2"
SRC_URI=""

LICENSE="as-is"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=""

src_install() {
	exeinto /usr/local/bin
	doexe bin/ec2-init.sh
	doexe bin/ec2-import-sshkeys.sh
	doexe bin/ec2-get-modules.sh
	doexe bin/ec2-get-metadata.sh
}
