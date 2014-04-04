#!/usr/bin/perl
$| = 1;
use strict;
use warnings;

use lib "../lib";
use civ2;
use civ2::filenames;

sub main(@);

exit main(@ARGV);

sub main(@) {
	my @args = @_;
	
	my $difficulty;
	do {
		if(defined($difficulty)) {
			print "No turn length data for difficulty '$difficulty'\n";
		}
		$difficulty = select_option('Please select a difficulty level', @civ2::difficulties_asc);
	} while (!defined($civ2::difficulty_intyear_yearsperturn->{ $difficulty }));
	
	print "Enter a year (eg 2050BC) or turn number (eg 143): ";
	my $inputstring = <STDIN>;
	chomp($inputstring);
	if($inputstring =~ /^\d+$/) {
		my $year = turnno_to_year($inputstring, $difficulty);
		
		print "Turn number $inputstring at $difficulty difficulty level is $year\n";
	} else {
		my $yearstring = uc($inputstring);
			
		my $turnno = year_to_turnno($yearstring, $difficulty);
		my $newyear = turnno_to_year($turnno, $difficulty);
		
		print "$newyear is turn number $turnno at $difficulty difficulty level\n";
	}
	
	return 0;
}

__END__
