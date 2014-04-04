#!/usr/bin/perl
$| = 1;
use strict;
use warnings;
use Cwd;
use File::Basename;

use lib "../lib";
use civ2;
use civ2::filenames;

sub main(@);

exit main(@ARGV);

sub main(@) {
	my @args = @_;
	
	my $saves_dir = 'E:\Program Files\Civilization 2\Saves';
	my $monitor_directory;
	if(@args) {
		$monitor_directory = shift(@args);
		if(! -d $monitor_directory) {
			$monitor_directory = $saves_dir . '/' . $monitor_directory;
		}
	} else {
		$monitor_directory = choose_savegame_dir($saves_dir);
	}
	
	if(! -d $monitor_directory) {
		die "Specified savesdir, '$monitor_directory', is not a directory.";
	}
	
	print "Monitoring for autosave files in $monitor_directory...\n";
	
	while(1) {
		my @autosave_files = get_sorted_autosavefilepaths_indir($monitor_directory);
		
		if(@autosave_files) {
			my $turnno_highestversionno = get_highest_versionno_per_turnno_indir($monitor_directory);
			foreach my $this_filepath (@autosave_files) {
				my $this_filename = fileparse($this_filepath);
				
				my $settings = read_savegame_settings($this_filepath);
				my $year = turnno_to_year($settings->{turn_number}, $settings->{difficulty});
				
				my $suffix = (
					$settings->{cheat_penalty} ?
					'_cheatsenabled' :
					''
				);
				
				my $versionno = (
					defined($turnno_highestversionno->{ $settings->{turn_number} }) ? 
					$turnno_highestversionno->{ $settings->{turn_number} } + 1 : 
					1
				);
				
				my $new_filename = format_filename($settings->{turn_number}, $year, $versionno, $suffix);
				my $new_filepath = $monitor_directory . '/' . $new_filename;
				
				if(-e $new_filepath) {
					die "Script failure. Tried to move '$this_filepath' to '$new_filepath', but the latter already exists.";
				}
				print "Moving $this_filename to $new_filename\n";
				rename($this_filepath, $new_filepath);
				make_file_readonly($new_filepath);
				$turnno_highestversionno->{ $settings->{turn_number} } = $versionno;
			}
		}
		
		sleep(1);
	}
	
	return 0;
}
































