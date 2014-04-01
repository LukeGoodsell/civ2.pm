#!/usr/bin/perl
$| = 1;
use strict;
use warnings;

use lib "../lib";
use civ2;

sub main(@);

exit main(@ARGV);

sub main(@) {
	my @args = @_;
	
	my $directory = 'E:\Program Files\Civilization 2\Saves\2014-03-26 Mao Zedong Deity\\';
	
	my ($dh);
	chdir($directory) or die $!;
	opendir($dh, $directory) or die $!;
	my @files = grep !/^\./, readdir($dh);
	closedir($dh);
	
	foreach my $this_file (@files) {
		$this_file =~ /^ma_(a|b)[\d]+([^\d].*)?\.sav$/ or next;
		my $suffix = $2;
		if($suffix and length($suffix) > 0) {
			if(substr($suffix, 0, 1) ne '_') {
				$suffix = '_' . $suffix;
			}
		} else {
			$suffix = '';
		}
		
		my $turn_number = get_savegame_turn_number($this_file);
		my $difficulty = get_savegame_difficulty($this_file);
		my $year = intyear_to_adbc(turnno_to_intyear($difficulty, $turn_number));
		my $new_filename = sprintf("turn%04d_%s%s.sav", $turn_number, $year, $suffix);
		
		print "Moving $this_file to $new_filename\n";
		
		if(-e $new_filename) {
			die "new file already exists";
		}
		
		rename($this_file, $new_filename);
	}
	
	return 0;
}

__END__
