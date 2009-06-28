use Module::Build;
use Config;

my $build = Module::Build->new
  (
   module_name => 'ExtUtils::ParseXS',
   license => 'perl',
   installdirs => 'core',
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

