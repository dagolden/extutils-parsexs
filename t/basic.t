# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 4 };
use ExtUtils::ParseXS qw(process_file);
ok(1); # If we made it this far, we're loaded.

use strict;
use Config;
use File::Spec;

chdir 't';

#########################

# Try sending to filehandle
tie *FH, 'Foo';
process_file( filename => 'XSTest.xs', output => \*FH, prototypes => 0 );
ok tied(*FH)->content, '/is_even/', "Test that output contains some text";


process_file( filename => 'XSTest.xs', output => 'XSTest.c', prototypes => 0);
ok -e 'XSTest.c', 1, "Create an output file";

# Try to compile it!  Don't get too fancy, though.
if ($Config{cc}) {
  my $corelib = File::Spec->catdir($Config{archlib}, 'CORE');
  my $command = "$Config{cc} -c $Config{ccflags} -I$corelib -o XSTest.o XSTest.c";
  
  print "$command\n";
  ok !system($command);
} else {
  skip "Skipped can't find a C compiler", 1;
}

sub Foo::TIEHANDLE { bless {}, 'Foo' }
sub Foo::PRINT { shift->{buf} .= join '', @_ }
sub Foo::content { shift->{buf} }
