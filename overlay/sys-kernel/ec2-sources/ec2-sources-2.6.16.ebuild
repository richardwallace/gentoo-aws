ETYPE="sources"
inherit kernel-2

DESCRIPTION="EC2 kernel source"
HOMEPAGE="http://www.kernel.org"
SRC_URI="http://s3.amazonaws.com/ec2-downloads/linux-2.6.16-ec2.tgz"

KEYWORDS="amd64 x86"
S=${WORKDIR}

src_unpack() {
   unpack ${A}
   cd "${S}"
   mv linux-2.6.16-xenU linux-2.6.16-ec2
}
