use Module::Build;
use Config;

my $class = Module::Build->subclass(code => <<'EOF');
  sub do_create_makefile_pl {
    my $self = shift;
    $self->SUPER::do_create_makefile_pl(fh => $fh);
    $self->do_system(qw(perl -pi -e), q{s/'INSTALLDIRS' => '\w+'/'INSTALLDIRS' => (\$] >= 5.009003 ? 'perl' : 'site')/}, 'Makefile.PL');
  }
EOF

my $build = $class->new
  (
   module_name => 'ExtUtils::ParseXS',
   license => 'perl',
   installdirs => ($] >= 5.009003 ? 'core' : 'site'),
   auto_configure_requires => 0,
   requires => {
     'Cwd' => 0,
     'Exporter' => 0,
     'File::Basename' => 0,
     'File::Spec' => 0,
     'Symbol' => 0,
   },
   build_requires => {
     'Carp' => 0,
     'DynaLoader' => 0,
     'ExtUtils::CBuilder' => 0,
     'Test::More' => 0.47,
   },
   add_to_cleanup => ["t/XSTest.c", "t/XSTest$Config{obj_ext}", "t/XSTest.$Config{dlext}"],
   create_makefile_pl => 'traditional',
   create_readme => 1,
  );

$build->create_build_script;

