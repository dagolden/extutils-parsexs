
use ExtUtils::MakeMaker;
use Config;
use 5.006;

my $module = 'ExtUtils::ParseXS';
my ($file, $dir);
$file = 'lib/' . join('/', split /::/, $module) . '.pm';
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $file,
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               PREOP=>('rm -f README; '.
                       "pod2text -80 < $file > README; ".
                       "cp -f README $dir-\$(VERSION); "
                      ),
             },
   'clean' => {FILES => "t/XSTest.c t/XSTest$Config{obj_ext} t/XSTest.$Config{dlext}"},
   'INSTALLDIRS' => 'perl', # Install in the core perl directory, not site_perl,
                            # because that's where MakeMaker will look.
   'PREREQ_PM' => {
		   Cwd => 0,
		   Config => 0,
		   File::Basename => 0,
		   File::Spec => 0,
		   Exporter => 0,
		  },
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $file, # retrieve abstract from module
     AUTHOR     => 'Ken Williams <ken@mathforum.org>') : 
    ()
   ),
  );

