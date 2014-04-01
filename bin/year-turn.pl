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
	
	print "Testing...\n";
	foreach my $test_difficulty (keys(%{ $civ2::difficulty_intyear_yearsperturn })) {
		for(my $testturn = 1; $testturn < 1000; $testturn++) {
			my $testyear = intyear_to_adbc(turnno_to_intyear($test_difficulty, $testturn));
			my $testturnback = intyear_to_turnno($test_difficulty, adbc_to_intyear($testyear));
			if($testturn != $testturnback) {
				print "Error for turn '$testturn': $testyear, $testturnback, $test_difficulty\n";
			}
		}
	}
	print "Done\n\n";
	
	print "Enter a difficulty (eg King): ";
	my $difficulty = <STDIN>;
	chomp($difficulty);
	
	if(!defined($civ2::difficulty_intyear_yearsperturn->{ $difficulty })) {
		die "No turn length data for difficulty '$difficulty'\n";
	}
	
	print "Enter a year (eg 2050BC): ";
	my $yearstring = <STDIN>;
	chomp($yearstring);
	$yearstring = uc($yearstring);
	
	my $intyear = adbc_to_intyear($yearstring);
	
	my $turnno = intyear_to_turnno($difficulty, $intyear);
	
	print "$yearstring is turn number $turnno at $difficulty difficulty level\n";
	
	my $newyear = intyear_to_adbc(turnno_to_intyear($difficulty, $turnno));
	print "Turn $turnno at $difficulty difficulty level is $newyear\n";
	
	
	return 0;
}

__END__
