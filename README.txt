gentoo-aws
==========

Fork of gentoo-aws project (http://code.google.com/p/gentoo-aws/) that helps build a Gentoo AMI for Amazon EC2.

USAGE
-----

The following commands should be executed from shell on a running EC2 instance.  Tested with the Amazon developer image (ami-2f5fba46)

  ./scripts/build-stage3-image.sh
  ./scripts/build-ec2-image.sh -i <IMAGE NAME>
