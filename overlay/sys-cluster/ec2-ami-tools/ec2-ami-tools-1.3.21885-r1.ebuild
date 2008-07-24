# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="Amazon EC2 AMI Tools"
HOMEPAGE="http://developer.amazonwebservices.com/connect/entry.jspa?entryID=368&ref=featured"
SRC_URI="http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools-1.3-21885.zip"
LICENSE="as-is"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

RDEPEND="dev-lang/ruby net-misc/curl"
DEPEND="${RDEPEND}"

S=${WORKDIR}/ec2-ami-tools-1.3-21885

src_install () {
	insinto /usr/lib/aes/amiutil/lib 
	doins -r ${S}/lib/*

	insinto /etc
	doins -r ${S}/etc/*

	exeinto /usr/lib/aes/amiutil
	doexe ${S}/bin/*

	insinto /usr/bin
	for exe in ${S}/bin/*; do
		target="$(basename $exe)"
		base="$(basename ${exe})"
		ln -s /usr/lib/aes/amiutil/$target ${D}/usr/bin/${base}
	done

        dodir /etc/env.d
        echo "EC2_AMITOOL_HOME=/usr/lib/aes/amiutil" >> ${D}/etc/env.d/99ec2
}
