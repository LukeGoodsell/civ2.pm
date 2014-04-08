#!/usr/bin/perl
$| = 1;
use strict;
use warnings;
use File::Basename;
use lib "../lib";
use civ2;
use civ2::filenames;
use civ2::debug;


my @test_paths = (
	'/foo/bar/fish.wibble',
	'/foo/bar/fish.',
	'/foo/bar/fish',
	'/foo/bar/fish.asdf.d',
	'/foo/bar/fish.wibble.',
	'/fish.wibble',
	'fish.wibble',
);

foreach my $this_path (@test_paths) {
	print "Current path: $this_path\n";
	my ($this_basename, $parentdir, $extension) = fileparse($this_path, qr/\.[^.]*$/);
	my $this_filename = $this_basename . $extension;

	foreach my $var (qw/$parentdir $this_filename $this_basename $extension/) {
		print "$var = '" . eval($var) . "'\n";
	}
	
	print "\n\n";
}


__END__

