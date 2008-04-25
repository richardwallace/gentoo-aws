# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

MY_P=${PN}-20080421
DESCRIPTION="Gentoo EC2 instance scripts"
HOMEPAGE="http://code.google.com/p/cloudapi/"
SRC_URI="http://cloudapi.googlecode.com/files/gentoo-ec2-20080421.tar.gz"
LICENSE="as-is"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=""
S=${WORKDIR}/${MY_P}

src_install() {
	exeinto /usr/local/bin	
	doexe ec2-init.sh
	doexe ec2-import-sshkeys.sh
	doexe ec2-get-modules.sh
	doexe ec2-get-metadata.sh
}
