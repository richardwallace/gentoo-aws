# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils rpm

DESCRIPTION="Amazon EC2 AMI Tools"
HOMEPAGE="http://developer.amazonwebservices.com/connect/entry.jspa?entryID=368&ref=featured"
SRC_URI="http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools-1.3-20041.noarch.rpm"
LICENSE="as-is"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

RDEPEND="dev-lang/ruby net-misc/curl"
DEPEND="${RDEPEND}"

S=${WORKDIR}

src_install () {
	cd ${S}

	insinto /usr/lib/ruby/site_ruby
	doins -r ${S}/usr/lib/site_ruby/*

	insinto /etc
	doins -r ${S}/etc/*

	exeinto /usr/lib/aes/amiutil
	doexe ${S}/usr/local/aes/amiutil/*

	insinto /usr/bin
	for exe in ${S}/usr/local/bin/*; do
		if [ -h "${exe}" ]; then
			target="$(basename `readlink ${exe}`)"
			base="$(basename ${exe})"
			ln -s /usr/lib/aes/amiutil/$target ${D}/usr/bin/${base}
		fi
	done

	sed -i -e 's:site_ruby:ruby/site_ruby:' ${D}/usr/lib/aes/amiutil/*
}
