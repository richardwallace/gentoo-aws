inherit perl-app

DESCRIPTION="maatkit - contains essential command-line tools for MySQL, such as table checksums, a query profiler, and a visual EXPLAIN tool."
HOMEPAGE="http://sourceforge.net/projects/maatkit/"
SRC_URI="mirror://sourceforge/maatkit/${P}.tar.gz"

LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~x86 ~amd64"
SLOT="0"
IUSE=""

DEPEND=">=dev-perl/DBD-mysql-1.0
		>=dev-perl/DBI-1.13"

src_install() {
	perl-module_src_install
}

