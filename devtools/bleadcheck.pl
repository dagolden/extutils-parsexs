#!/usr/bin/perl

# A script to check a local copy against bleadperl, generating a blead
# patch if they're out of sync.  The path to bleadperl is required.
# An optional directory argument will be chdir()-ed into before comparing.

use strict;
my $blead = shift @ARGV
  or die "Usage: $0 <bleadperl-src> [ExtUtils-ParseXS-src]\n";

chdir shift() if @ARGV;


diff( "$blead/lib/ExtUtils/ParseXS.pm", "lib/ExtUtils/ParseXS.pm");
diff( "$blead/lib/ExtUtils/xsubpp", "lib/ExtUtils/xsubpp");
diff( "$blead/lib/ExtUtils/ParseXS", "lib/ExtUtils/ParseXS",
      qw(t Changes .svn) );

diff( "$blead/lib/ExtUtils/ParseXS/t", "t",
      qw(.svn) );

######################
sub diff {
  my ($first, $second, @skip) = @_;
  local $_ = `diff -ur $first $second`;

  for my $x (@skip) {
    s/^Only in .* $x\n//mg;
  }
  print;
}
