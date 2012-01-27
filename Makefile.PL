use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'API::DirectAdmin',
    VERSION_FROM      => 'lib/API/DirectAdmin.pm',
    PREREQ_PM         => {
        'Data::Dumper'   => '0',
        'LWP::UserAgent' => '0',
		'HTTP::Request'  => '0',
		'URI'   		 => '0',
		'Carp'   		 => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/API/DirectAdmin.pm', # retrieve abstract from module
       AUTHOR         => 'Andrey "Chips" Kuzmin <kaachips@gmail.com>') : ()),
);
