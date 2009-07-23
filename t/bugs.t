#!/usr/bin/perl

BEGIN {
  if ($ENV{PERL_CORE}) {
    chdir 't' if -d 't';
    chdir '../lib/ExtUtils/ParseXS'
      or die "Can't chdir to lib/ExtUtils/ParseXS: $!";
    @INC = qw(../.. ../../.. .);
  }
}
use strict;
use Test::More;
use Config;
use DynaLoader;
use ExtUtils::CBuilder;

# paths relative to t/
my @bugs = (
  {
    xs_options => {
      filename  => 'bugs/RT48104.xs',
      'C++'     => 1,
      typemap   => 'typemap',
    },
    cb_options => {
      extra_compiler_flags => ['-x', 'c++', '-Iinclude'],
    },
  },
);

plan tests => 1 + 3 * @bugs;

my ($source_file, $obj_file, $lib_file);

require_ok( 'ExtUtils::ParseXS' );
ExtUtils::ParseXS->import('process_file');

chdir 't' or die "Can't chdir to t/, $!";

use Carp; $SIG{__WARN__} = \&Carp::cluck;

#########################

for my $bug ( @bugs ) {

  $source_file = 'XSTest.c';

  # Try sending to file
  process_file(output => $source_file, prototypes => 0, %{$bug->{xs_options}});
  ok -e $source_file, "Create an output file";

  my $quiet = $ENV{PERL_CORE} && !$ENV{HARNESS_ACTIVE};
  my $b = ExtUtils::CBuilder->new(quiet => $quiet);

  SKIP: {
    skip "no compiler available", 2
      if ! $b->have_compiler;
    $obj_file = $b->compile( source => $source_file, %{$bug->{cb_options}} );
    ok $obj_file;
    ok -e $obj_file, "Make sure $obj_file exists";
  }

#  SKIP: {
#    skip "no dynamic loading", 5
#      if !$b->have_compiler || !$Config{usedl};
#    my $module = 'XSTest';
#    $lib_file = $b->link( objects => $obj_file, module_name => $module );
#    ok $lib_file;
#    ok -e $lib_file,  "Make sure $lib_file exists";
#
#    eval {require XSTest};
#    is $@, '';
#    ok  XSTest::is_even(8);
#    ok !XSTest::is_even(9);
#
#    # Win32 needs to close the DLL before it can unlink it, but unfortunately
#    # dl_unload_file was missing on Win32 prior to perl change #24679!
#    if ($^O eq 'MSWin32' and defined &DynaLoader::dl_unload_file) {
#      for (my $i = 0; $i < @DynaLoader::dl_modules; $i++) {
#        if ($DynaLoader::dl_modules[$i] eq $module) {
#          DynaLoader::dl_unload_file($DynaLoader::dl_librefs[$i]);
#          last;
#        }
#      }
#    }
#  }
}

unless ($ENV{PERL_NO_CLEANUP}) {
  for ( $obj_file, $lib_file, $source_file) {
    next unless defined $_;
    1 while unlink $_;
  }
}

