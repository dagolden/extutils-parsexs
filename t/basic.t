# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 9 };
use ExtUtils::ParseXS qw(process_file);
ok(1); # If we made it this far, we're loaded.

use strict;
use Config;
use File::Spec;

chdir 't';

use Carp; $SIG{__WARN__} = \&Carp::cluck;

#########################

# Try sending to filehandle
tie *FH, 'Foo';
process_file( filename => 'XSTest.xs', output => \*FH, prototypes => 1 );
ok tied(*FH)->content, '/is_even/', "Test that output contains some text";

# Try sending to file
process_file( filename => 'XSTest.xs', output => 'XSTest.c', prototypes => 0 );
ok -e 'XSTest.c', 1, "Create an output file";

# Try to compile the file!  Don't get too fancy, though.
if (have_compiler()) {
  my $corelib = File::Spec->catdir($Config{archlib}, 'CORE');
  my $o_file = "XSTest$Config{obj_ext}";

  ok !do_system("$Config{cc} -c $Config{ccflags} -I$corelib -o $o_file XSTest.c");
  ok -e $o_file, 1, "Make sure $o_file exists";
  
  my $lib_file = "XSTest.$Config{dlext}";
  ok !do_system("$Config{shrpenv} $Config{ld} $Config{lddlflags} -o $lib_file $o_file");

  eval {require XSTest};
  ok $@, '';
  ok  XSTest::is_even(8);
  ok !XSTest::is_even(9);

} else {
  skip "Skipped can't find a C compiler & linker", 1 for 1..6;
}

#####################################################################

sub find_in_path {
  my $thing = shift;
  my @path = split ':', $ENV{PATH};
  foreach (@path) {
    my $fullpath = File::Spec->catfile($_, $thing);
    return $fullpath if -e $fullpath;
  }
  return;
}

sub have_compiler {
  my %things;
  foreach (qw(cc ld)) {
    return 0 unless $Config{$_};
    $things{$_} = (File::Spec->file_name_is_absolute($Config{cc}) ?
		   $Config{cc} :
		   find_in_path($Config{cc}));
    return 0 unless $things{$_};
    return 0 unless -x $things{$_};
  }
  return 1;
}

sub do_system {
  my $cmd = shift;
  print "$cmd\n";
  return system($cmd);
}


sub Foo::TIEHANDLE { bless {}, 'Foo' }
sub Foo::PRINT { shift->{buf} .= join '', @_ }
sub Foo::content { shift->{buf} }
