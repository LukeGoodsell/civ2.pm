#!/usr/bin/perl
$| = 1;
use strict;
use warnings;
use File::Basename;

use lib "../lib";
use civ2;
use civ2::filenames;

sub main(@);

exit main(@ARGV);

sub main(@) {
	my @args = @_;
	
	my $saves_dir = 'E:\Program Files\Civilization 2\Saves';
	my $directory;
	if(@args) {
		$directory = shift(@args);
		if(! -d $directory) {
			$directory = $saves_dir . '/' . $directory;
		}
	} else {
		$directory = choose_savegame_dir($saves_dir);
	}
	
	if(! -d $directory) {
		die "Specified savesdir, '$directory', is not a directory.";
	}
	
	my @files = get_sorted_savegamefilepaths_indir($directory);
	my $turnno_highestversionno = get_highest_versionno_per_turnno_indir($directory);
	
	foreach my $this_filepath (@files) {
		# Exclude already-formatted filenames:
		!parse_formatted_filepath($this_filepath) or next;
		
		my ($this_basename, $parentdir, $extension) = fileparse($this_filepath, qr/\.[^.]*$/);
		my $this_filename = $this_basename . $extension;
		
		# Try to identify useful info as a suffix
		my $suffix;
		if(my $autosave_filepath_parsedata = parse_autosave_filepath($this_filename)) {
			# The file is an autosave filepath. There is not useful info to be obtained
		} elsif(my $default_filepath_parsedata = parse_default_filepath($this_filename)) {
			# The default savegame filename, possibly with a suffix
			# eg: ma_a980.sav ma_a980b.sav ma_a980_asdf.sav
			$suffix = $default_filepath_parsedata->{suffix};
		} else {
			# Any other filename
			$suffix = $this_basename;
		}
		
		if(defined($suffix) and length($suffix) > 0) {
			if(substr($suffix, 0, 1) ne '_') {
				$suffix = '_' . $suffix;
			}
		} else {
			$suffix = '';
		}
		
		my $settings = read_savegame_settings($this_filepath);
		my $year = turnno_to_year($settings->{turn_number}, $settings->{difficulty});
		$suffix = (
			$settings->{cheat_penalty} ?
			'_cheatsenabled' :
			''
		) . $suffix;
		
		my $versionno = (
			defined($turnno_highestversionno->{ $settings->{turn_number} }) ? 
			$turnno_highestversionno->{ $settings->{turn_number} } + 1 : 
			1
		);
		
		my $new_filename = $directory . '/' . format_filename($settings->{turn_number}, $year, $versionno, $suffix);
		
		if(-e $new_filename) {
			die "script failure";
		}
		print "Moving $this_filepath to $new_filename\n";
		rename($this_filepath, $new_filename) or die "Couldn't move file: $!";
		make_file_readonly($new_filename);
		$turnno_highestversionno->{ $settings->{turn_number} } = $versionno;
	}
	
	return 0;
}

__END__
