#!/usr/bin/perl
$| = 1;
use strict;
use warnings;
use lib "../lib";
use civ2;
use civ2::filenames;
use civ2::debug;




my $dir = 'E:\Program Files\Civilization 2\Saves\temp';


my $turnno_highestversionno = get_highest_versionno_per_turnno_indir($dir);
my $turnno_versions = get_existing_savegame_numbers_indir($dir);

printvar('turnno_versions', $turnno_versions);
printvar('turnno_highestversionno', $turnno_highestversionno);

my $autosave_filepath = 'Ma_Auto.SAV';
my $nonautosave_filepath = 'ma_a1790.sav';
#my $parsed_autosave_filepath = parse_autosave_filepath($autosave_filepath);
#printvar('$parsed_autosave_filepath', $parsed_autosave_filepath);

if(my $test = parse_autosave_filepath($autosave_filepath)){
	printvar('$test', $test);
} else {
	print "\$test is not an autosave filepath\n";
}

if(my $test2 = parse_autosave_filepath($nonautosave_filepath)){
	printvar('$test2', $test2);
} else {
	print "\$test2 is not an autosave filepath\n";
}



__END__

