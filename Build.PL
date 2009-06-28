use Module::Build;
use Config;

my $build = Module::Build->new
  (
   module_name => 'ExtUtils::ParseXS',
   license => 'perl',
   installdirs => 'core',
   requires => {
		'Cwd' => 0,
		'Config' => 0,
		'File::Basename' => 0,
		'File::Spec' => 0,
		'Exporter' => 0,
	       },
   build_requires => {
		      'ExtUtils::CBuilder' => 0,
		     },
   add_to_cleanup => ["t/XSTest.c", "t/XSTest$Config{obj_ext}", "t/XSTest.$Config{dlext}"],
   create_makefile_pl => 'traditional',
   create_readme => 1,
  );

$build->create_build_script;
