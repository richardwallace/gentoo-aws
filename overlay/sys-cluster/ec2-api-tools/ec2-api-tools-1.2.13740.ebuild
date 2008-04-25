# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

MY_P=${PN}-1.3-19403
DESCRIPTION="Amazon EC2 Command Line Tools"
HOMEPAGE="http://developer.amazonwebservices.com/connect/entry.jspa?externalID=351&categoryID=88"
SRC_URI="http://s3.amazonaws.com/ec2-downloads/ec2-api-tools-1.3-19403.zip"
LICENSE="as-is"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=">=virtual/jre-1.5 app-arch/unzip"
S=${WORKDIR}/${MY_P}

src_install() {
	cd ${S}
	insinto /opt/ec2/lib
	doins lib/*
	exeinto /opt/ec2/bin
	doexe bin/*

	dodir /etc/env.d
	echo "PATH=/opt/ec2/bin" > ${D}/etc/env.d/99ec2
	echo "EC2_HOME=/opt/ec2" >> ${D}/etc/env.d/99ec2
}
