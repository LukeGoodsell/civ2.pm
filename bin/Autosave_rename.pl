#!/usr/bin/perl
$| = 1;
use strict;
use warnings;
use Cwd;
use POSIX qw(ceil);
use Win32::File;

use lib "../lib";
use civ2;

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
		opendir(SAVES_DIR, $saves_dir) or die "Couldn't opendir '$saves_dir': $!";
		my $dirid = 0;
		my %save_dirs = map { ++$dirid => $_ } sort{ $a cmp $b } grep { !/^\./ and -d "$saves_dir/$_" } readdir(SAVES_DIR);
		closedir(SAVES_DIR);
		
		my $numdigits = ceil(log($dirid + 1) / log(10));
		print "dirid: $dirid; numdigits: $numdigits\n";
		my $chosen_dirid;
		
		do {
			print "Please select a save directory to monitor:\n";
			foreach my $this_dirid (sort({$a <=> $b} (keys(%save_dirs)))) {
				printf(" %${numdigits}u : %s\n", $this_dirid, $save_dirs{$this_dirid});
			}
			print "Number: ";
			$chosen_dirid = <STDIN>;
			chomp($chosen_dirid);
		} while (!defined($chosen_dirid) or $chosen_dirid !~ /^\d+$/ or !defined($save_dirs{$chosen_dirid}));
		
		$monitor_directory = $saves_dir . '/' . $save_dirs{$chosen_dirid};
	}
	
	if(! -d $monitor_directory) {
		die "Specified savesdir, '$monitor_directory', is not a directory.";
	}
	
	print "Monitoring for autosave files in $monitor_directory...\n";
	
	while(1) {
		my @autosave_files = get_sorted_autosave_files($monitor_directory);
		
		foreach my $filename (@autosave_files) {
			my $turn_number = get_savegame_turn_number($filename);
			my $difficulty = get_savegame_difficulty($filename);
			my $year = intyear_to_adbc(turnno_to_intyear($difficulty, $turn_number));
			my $new_filename;
			my $counter = 0;
			do {
				$counter++;
				$new_filename = $monitor_directory . '/' . sprintf("turn%04d_%s_%03d.sav", $turn_number, $year, $counter);
			} while(-e $new_filename);
			print "Moving $filename to $new_filename\n";
			rename($filename, $new_filename);
			make_file_readonly($new_filename);
		}
		
		sleep(1);
	}
	
	return 0;
}































