ETYPE="sources"
inherit kernel-2

DESCRIPTION="EC2 kernel source"
HOMEPAGE="http://www.kernel.org"
SRC_URI="http://ec2-downloads.s3.amazonaws.com/xen-3.1.0-src-ec2-v1.0.tgz"

KEYWORDS="amd64 x86"
S=${WORKDIR}

src_unpack() {
	unpack ${A}
	cd ${S}
	mv xen-3.1.0-src-ec2-v1.0/linux-2.6.18.tar.bz2 .
	tar xjvf linux-2.6.18.tar.bz2
	mv linux-2.6.18 linux-2.6.18-ec2
}
