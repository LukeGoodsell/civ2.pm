package civ2::filenames;


# Dependencies
use strict;
use warnings;
use base 'Exporter';
use File::Basename;
use Sort::Naturally;
use POSIX qw(ceil);


# Subroutine declarations
sub choose_savegame_dir($);
sub select_option($@);
sub get_existing_savegame_numbers_indir($);
sub get_highest_versionno_per_turnno_indir($);
sub get_savegamefilepaths_indir($);
sub get_sorted_savegamefilepaths_indir($);
sub get_autosavefilepaths_indir($);
sub get_sorted_autosavefilepaths_indir($);
sub format_filename($$$$);
sub parse_autosave_filepath($);
sub parse_formatted_filepath($);


# Module info
our $VERSION = '0.02';
our @EXPORT = qw(
	choose_savegame_dir
	select_option
	get_existing_savegame_numbers_indir
	get_highest_versionno_per_turnno_indir
	get_savegamefilepaths_indir
	get_sorted_savegamefilepaths_indir
	get_autosavefilepaths_indir
	get_sorted_autosavefilepaths_indir
	format_filename
	parse_autosave_filepath
	parse_formatted_filepath
	sortby_filemoddate
);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = qw();


# Subroutines

sub choose_savegame_dir($) {
	my ($saves_dir) = @_;
	
	opendir(SAVES_DIR, $saves_dir) or die "Couldn't opendir '$saves_dir': $!";
	my @save_dirs = nsort grep { !/^\./ and -d "$saves_dir/$_" } readdir(SAVES_DIR);
	closedir(SAVES_DIR);
	
	my $selected_dir = select_option('Please select a save directory to monitor', @save_dirs);
	
	return $saves_dir . '/' . $selected_dir;
}

sub select_option($@) {
	my ($message, @options) = @_;
	
	my $numdigits = ceil(log(scalar(@options) + 1) / log(10));
	
	my $chosen_optionnum;
	
	do {
		print "$message:\n";
		for(my $optionnum = 1; $optionnum <= scalar(@options); $optionnum++) {
			printf(" %${numdigits}u : %s\n", $optionnum, $options[$optionnum - 1]);
		}
		print "Number: ";
		$chosen_optionnum = <STDIN>;
		chomp($chosen_optionnum);
	} while (!defined($chosen_optionnum) or $chosen_optionnum !~ /^\d+$/ or $chosen_optionnum > scalar(@options) or $chosen_optionnum < 1);
	
	return $options[$chosen_optionnum - 1];
}

sub get_existing_savegame_numbers_indir($) {
	my ($directory) = @_;
	my $turnno_versions = {};
	my @savegamefilepaths = get_savegamefilepaths_indir($directory);
	foreach my $this_filepath (@savegamefilepaths) {
		my $filename_data = parse_formatted_filepath($this_filepath);
		
		if(defined($filename_data)) {
			$turnno_versions->{ $filename_data->{turn_number} }->{ $filename_data->{year_version_number} } = 1;
		}
	}
	return $turnno_versions;
}

sub get_highest_versionno_per_turnno_indir($) {
	my ($directory) = @_;
	my $turnno_versions = get_existing_savegame_numbers_indir($directory);
	my $turnno_to_highestversionno = {};
	foreach my $turnno (keys(%{ $turnno_versions })) {
		foreach my $versionno (keys(%{ $turnno_versions->{$turnno} })) {
			if(defined($turnno_to_highestversionno->{ $turnno })) {
				if($versionno > $turnno_to_highestversionno->{ $turnno }) {
					$turnno_to_highestversionno->{ $turnno } = $versionno;
				}
			} else {
				$turnno_to_highestversionno->{ $turnno } = $versionno;
			}
		}
	}
	return $turnno_to_highestversionno;
}

sub get_savegamefilepaths_indir($) {
    my ($dirpath) = @_;
    opendir(my($dir), $dirpath) or die "can't opendir '$dirpath': $!";
    my @savegame_files = map {$dirpath . '/' . $_} grep { /\.sav$/i and !/^\./ } readdir $dir;
    closedir ($dir);
	return sort( sortby_filemoddate @savegame_files );
}

sub get_sorted_savegamefilepaths_indir($) {
    my ($dirpath) = @_;
	return sort( sortby_filemoddate get_savegamefilepaths_indir($dirpath) );
}

sub get_autosavefilepaths_indir($) {
    my ($dirpath) = @_;
	return grep { parse_autosave_filepath($_) } get_savegamefilepaths_indir($dirpath);
}

sub get_sorted_autosavefilepaths_indir($) {
    my $path = shift;
	return sort( sortby_filemoddate get_autosavefilepaths_indir($path) );
}

sub parse_autosave_filepath($) {
	my ($path) = @_;
	my $filename = fileparse($path);

	if($filename =~ /^([a-z]{2})_auto(\d?)\.sav$/i) {
		return {
			leader	=> $1,
			save_number	=> $2,
		};
	} else {
		return;
	}
}

sub format_filename($$$$) {
	my ($turn_number, $year, $versionno, $suffix) = @_;
	if(defined($suffix) and length($suffix) > 0) {
		if(substr($suffix, 0, 1) ne '_') {
			$suffix = '_' . $suffix;
		}
	} else {
		$suffix = '';
	}
	return sprintf('turn%04d_%s_%03d%s.sav', $turn_number, $year, $versionno, $suffix);
}

sub parse_formatted_filepath($) {
	my ($path) = @_;
	my $filename = fileparse($path);
	
	if($filename =~ /^turn([\d]+)_(\d+(AD|BC))_([\d]+)([^\d].*)?\.sav$/i) {
		my $turnno = $1;
		my $year = $2;
		my $adbc = $3;
		my $versionno = $4;
		my $raw_suffix = $5;
		$turnno =~ s/^0+//;
		$versionno =~ s/^0+//;
		my ($cheats_enabled);
		my $unparsed_suffix = $raw_suffix;
		if($unparsed_suffix) {
			if($unparsed_suffix =~ /_cheatsenabled/) {
				$unparsed_suffix =~ s/_cheatsenabled//gi;
				$cheats_enabled = 1;
			}
		}
		my $results = {
			turn_number			=> $turnno,
			year				=> $year,
			adbc				=> $adbc,
			year_version_number	=> $versionno,
			raw_suffix			=> $raw_suffix,
			unparsed_suffix		=> $unparsed_suffix,
			cheats_enabled		=> $cheats_enabled,
		};
		
		return $results;
	} else {
		return;
	}
}

sub sortby_filemoddate {
	-f $a or die "'$a' is not a file";
	-f $b or die "'$b' is not a file";
	
	return (stat($a))[9] <=> (stat($b))[9];
}

1;
