use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::DBI::Table',
	'DISTNAME'	=> 'Tk-DBI-Table',
	'VERSION'	=> '0.01',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 'Tk' => 0, 'Tk::ResizeButton' => 0 },

	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

