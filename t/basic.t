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

chdir 't' or die "Can't chdir to t/, $!";

use Carp; $SIG{__WARN__} = \&Carp::cluck;

my $Is_MSWin32 = $^O eq 'MSWin32';
my $BCC   = $Is_MSWin32 && $Config{cc} =~ /bcc32(\.exe)?$/;
my $MSVC  = $Is_MSWin32 && $Config{cc} =~ /cl(\.exe)?$/;
my $MinGW = $Is_MSWin32 && $Config{cc} =~ /gcc(\.exe)?$/;
my $Cygwin = $^O eq 'cygwin';

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
  my $module = 'XSTest';

  ok do_compile( $module );
  ok -e $module.$Config{obj_ext}, 1, "Make sure $module exists";

  ok do_link( $module );

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
  my @path = split $Config{path_sep}, $ENV{PATH};
  my @exe_ext = $Is_MSWin32 ?
    split($Config{path_sep}, $ENV{PATHEXT} || '.com;.exe;.bat') :
    ('');
  foreach (@path) {
    my $fullpath = File::Spec->catfile($_, $thing);
    foreach my $ext ( @exe_ext ) {
      return "$fullpath$ext" if -e "$fullpath$ext";
    }
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

sub do_compile {
  my $module   = shift;
  my $module_o = "$module$Config{obj_ext}";
  my $corelib  = File::Spec->catdir($Config{archlibexp}, 'CORE');
  my $cc_out   = $MSVC ? '-Fo' : $BCC ? '-o' : '-o ';
  return !do_system("$Config{cc} -c $Config{ccflags} -I$corelib $cc_out$module_o $module.c");
}

sub do_link {
  my $module     = shift;
  my $module_lib = "$module.$Config{dlext}";
  my $module_def = '';

  my $objs      = "$module$Config{obj_ext}";
  my $libs      = $Config{libs};
  my $lddlflags = $Config{lddlflags};
  my $ld_out    = '-o ';

  if ( $Is_MSWin32 or $Cygwin ) {
    require ExtUtils::Mksymlists;
    ExtUtils::Mksymlists::Mksymlists(
      'NAME' => $module, 'DLBASE' => $module, 'IMPORTS' => {} ) unless $Cygwin;

    if      ( $MSVC  ) { # Microsoft
      $ld_out     = '-out:';
      $libs      .= " $Config{libperl}";
      $module_def = "-def:$module.def";
    } elsif ( $BCC   ) { # Borland
      $objs       = "c0d32.obj $objs"; # Borland's startup obj; must be before others
      $ld_out     = '';
      $module_lib = ",$module_lib";
      $libs       = ",,$Config{libperl} $libs";
      $module_def = ",$module.def";
    } elsif ( $MinGW ) { # MinGW GCC
      (my $libperl = $Config{libperl}) =~ s/^(?:lib)?([^.]+).*$/$1/;
      $libs        = "-l$libperl $libs";
      do_system("dlltool --def $module.def --output-exp $module.exp");
      do_system("$Config{ld} $lddlflags -Wl,--base-file -Wl,$module.base $objs $ld_out$module_lib $libs $module.exp");
      do_system("dlltool --def $module.def --output-exp $module.exp --base-file $module.base");
      $module_def  = "$module.exp";
    } elsif ( $Cygwin ) { # MinGW GCC
      (my $libperl = $Config{libperl}) =~ s/^(?:lib)?([^.]+).*$/$1/;
      $libs        = "-L$Config{archlibexp}/CORE -l$libperl $libs";
      do_system("$Config{shrpenv} $Config{ld} $lddlflags -Wl,--base-file -Wl,$module.base $objs $ld_out$module_lib $libs");
    }
  }

  return !do_system("$Config{shrpenv} $Config{ld} $lddlflags $objs $ld_out$module_lib $libs $module_def");
}

sub do_system {
  my $cmd = shift;
  print "$cmd\n";
  return system($cmd);
}


sub Foo::TIEHANDLE { bless {}, 'Foo' }
sub Foo::PRINT { shift->{buf} .= join '', @_ }
sub Foo::content { shift->{buf} }
