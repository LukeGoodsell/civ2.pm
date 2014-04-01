#!/usr/bin/perl

use strict;
use warnings;
use lib "../lib";
use civ2;

my $filename = 'E:\Program Files\Civilization 2\Saves\temp\turn0310_1768AD_002.sav';
my $fh;
open($fh, '<', $filename) or die $!;
my $perm = (stat $fh)[2];
print $perm, "\n";
printf "permissions are %04o\n", $perm & 07777;
my $newperm = (stat $fh)[2] & 0555;
printf "new permissions are %04o\n", $newperm & 07777;
exit;

