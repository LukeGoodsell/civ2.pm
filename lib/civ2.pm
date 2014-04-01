package civ2;

# Dependencies
use strict;
use warnings;
use base 'Exporter';
use LWP::UserAgent;
use Fcntl qw(:seek);
use File::chmod;
use Time::localtime;

# Subroutine declarations
sub read_file_hexdata_at_offset($$$);
sub get_savegame_difficulty($);
sub get_savegame_turn_number($);
sub get_sorted_autosave_files($);
sub get_savegamefiles_indir($);
sub get_autosavefiles_indir($);
sub sort_files_by_moddate_asc(@);
sub adbc_to_intyear($);
sub intyear_to_adbc($);
sub intyear_to_turnno($$);
sub turnno_to_intyear($$);
sub make_file_readonly($);

# Module info
our $VERSION = '0.01';
our @EXPORT = qw(
	read_file_hexdata_at_offset
	get_savegame_difficulty
	get_savegame_turn_number
	get_sorted_autosave_files
	get_savegamefiles_indir
	get_autosavefiles_indir
	make_file_readonly
	sort_files_by_moddate_asc
	adbc_to_intyear
	intyear_to_adbc
	intyear_to_turnno
	turnno_to_intyear
);

# Global data
use constant {
	DIFFICULTY_CHIEFTAIN	=> 'Chieftain',
	DIFFICULTY_WARLORD		=> 'Warlord',
	DIFFICULTY_PRINCE		=> 'Prince',
	DIFFICULTY_KING			=> 'King',
	DIFFICULTY_EMPEROR		=> 'Emperor',
	DIFFICULTY_DEITY		=> 'Deity',
};

our $difficulty_adbc_yearsperturn = {
	&DIFFICULTY_KING	=> {
		'4000BC' 	=> 50,
		'1000BC' 	=> 25,
		'1AD'		=> 9,
		'10AD'		=> 10,
		'1500AD'	=> 5,
		'1750AD'	=> 2,
		'1850AD'	=> 1,
	},
	&DIFFICULTY_DEITY	=> {
		'4000BC' 	=> 50,
		'1000BC' 	=> 25,
		'1AD'		=> 19,
		'20AD'		=> 20,
		'1500AD'	=> 10,
		'1750AD'	=> 2,
		'1850AD'	=> 1,
	},
};

our $difficulty_intyear_yearsperturn = {};
foreach my $difficulty (keys(%{$difficulty_adbc_yearsperturn})) {
	foreach my $adbc (keys(%{$difficulty_adbc_yearsperturn->{ $difficulty }})) {
		my $yearsperturn = $difficulty_adbc_yearsperturn->{ $difficulty }->{ $adbc };
		my $intyear = adbc_to_intyear($adbc);
		$difficulty_intyear_yearsperturn->{ $difficulty }->{ $intyear } = $yearsperturn;
	}
}

# Subroutines

sub get_savegame_difficulty($) {
	my ($filename) = @_;
	
	my $difficulty_num = ord(read_file_hexdata_at_offset($filename, 44, 1));
	
	defined($difficulty_num) or die "No difficulty num";
	
	if($difficulty_num == 0) { return DIFFICULTY_CHIEFTAIN; }
	if($difficulty_num == 1) { return DIFFICULTY_WARLORD; }
	if($difficulty_num == 2) { return DIFFICULTY_PRINCE; }
	if($difficulty_num == 3) { return DIFFICULTY_KING; }
	if($difficulty_num == 4) { return DIFFICULTY_EMPEROR; }
	if($difficulty_num == 5) { return DIFFICULTY_DEITY; }
	
	die "Unknown difficulty number: '$difficulty_num'";
}

sub get_savegame_turn_number($) {
	my ($filename) = @_;
	
	return unpack("S", read_file_hexdata_at_offset($filename, 28, 2) );
}

sub read_file_hexdata_at_offset($$$) {
	my ($filename, $byte_position, $length) = @_;
	my($fh, $byte_value);

	#$filename      = "/some/file/name/goes/here";
	#$byte_position = 42;

	open($fh, "<", $filename)
		|| die "can't open $filename: $!";

	binmode($fh)
		|| die "can't binmode $filename";

	sysseek($fh, $byte_position, SEEK_CUR)  # NB: 0-based
		|| die "couldn't see to byte $byte_position in $filename: $!";

	sysread($fh, $byte_value, $length) == $length
		|| die "couldn't read byte from $filename: $!";
	
	return $byte_value;
	
	
	printf "read byte with ordinal value %#04x at position %d\n",
		ord($byte_value), $byte_position;
}

sub adbc_to_intyear($) {
	my $yearstring = shift;
	$yearstring =~ /^([\d]+)(AD?|BC?)$/i or die "Invalid year string: '$yearstring'";
	my ($number, $suffix) = ($1, $2);
	
	if($suffix =~ /AD?/i) {
		return $number;
	} else {
		return ($number - 1) * -1;
	}
	
	die;
}

sub intyear_to_adbc($) {
	my $intyear = shift;
	
	if($intyear < 1) {
		return (($intyear * -1) + 1) . 'BC';
	} else {
		return $intyear . 'AD';
	}
	
	die;
}

sub intyear_to_turnno($$) {
	my ($difficulty, $intyear) = @_;
	
	if(!defined($difficulty_intyear_yearsperturn->{ $difficulty })) {
		die "No turn length data for difficulty '$difficulty'";
	}
	my @intyear_boundaries = sort({$a <=> $b} keys(%{$difficulty_intyear_yearsperturn->{ $difficulty }}));
	
	my $turnno = 1;
	my $prev_boundary = shift(@intyear_boundaries);
	my $prev_yearsperturn = $difficulty_intyear_yearsperturn->{ $difficulty }->{ $prev_boundary };
	
	BOUNDARY:
	while(@intyear_boundaries) {
		my $next_boundary = shift(@intyear_boundaries);
		my $years_this_interval;
		
		if($intyear > $next_boundary) {
			$years_this_interval = $next_boundary - $prev_boundary;
		} else {
			$years_this_interval = $intyear - $prev_boundary;
		}
		
		$turnno += $years_this_interval / $prev_yearsperturn;
		$prev_boundary = $next_boundary;
		$prev_yearsperturn = $difficulty_intyear_yearsperturn->{ $difficulty }->{ $next_boundary };
		
		if($intyear <= $next_boundary) {
			last BOUNDARY;
		}
	}
	
	if($intyear > $prev_boundary) {
		$turnno += ($intyear - $prev_boundary) / $prev_yearsperturn;
	}
	
	return $turnno;
}

sub turnno_to_intyear($$) {
	my ($difficulty, $turnno) = @_;
	
	if(!defined($difficulty_intyear_yearsperturn->{ $difficulty })) {
		die "No turn length data for difficulty '$difficulty'";
	}
	my @intyear_boundaries = sort({$a <=> $b} keys(%{$difficulty_intyear_yearsperturn->{ $difficulty }}));
	
	my $intyear;
	my $prev_boundary = shift(@intyear_boundaries);
	my $prev_yearsperturn = $difficulty_intyear_yearsperturn->{ $difficulty }->{ $prev_boundary };
	
	my $turnsleft = $turnno - 1;
	
	BOUNDARY:
	while(@intyear_boundaries) {
		my $next_boundary = shift(@intyear_boundaries);
		my $turns_this_interval = ($next_boundary - $prev_boundary) / $prev_yearsperturn;
		
		if($turnsleft > $turns_this_interval) {
			$turnsleft -= $turns_this_interval;
			$prev_boundary = $next_boundary;
			$prev_yearsperturn = $difficulty_intyear_yearsperturn->{ $difficulty }->{ $next_boundary };
			next BOUNDARY;
		}
		
		return $prev_boundary + ($turnsleft * $prev_yearsperturn);
	}
		
	return $prev_boundary + ($turnsleft * $prev_yearsperturn);
}

sub get_sorted_autosave_files($) {
    my $path = shift;
	return sort_files_by_moddate_asc(get_autosavefiles_indir($path));
	
	
    opendir my($dir), $path or die "can't opendir $path: $!";
    my %hash = map {$_ => (stat($path . '/' . $_))[9]}
               grep { /\.sav$/i and !/^\./ }
               readdir $dir;
    closedir $dir;
	return sort( { $hash{$a} <=> $hash{$b} } keys(%hash) );
}

sub get_savegamefiles_indir($) {
    my ($dirpath) = @_;
    opendir(my($dir), $dirpath) or die "can't opendir '$dirpath': $!";
    my @savegame_files = map {$dirpath . '/' . $_} grep { /\.sav$/i and !/^\./ } readdir $dir;
    closedir ($dir);
	return @savegame_files;
}

sub get_autosavefiles_indir($) {
    my ($dirpath) = @_;
	return grep { /_auto\.sav$/i } get_savegamefiles_indir($dirpath);
}

sub sort_files_by_moddate_asc(@) {
	my @filepaths = @_;
	my %filepaths_hash = map {$_ => (stat($_))[9]} @filepaths;
	return sort( { $filepaths_hash{$a} <=> $filepaths_hash{$b} } keys(%filepaths_hash) );
}

sub make_file_readonly($) {
	my ($filepath) = @_;
	-f $filepath or die "Not a file path: $filepath";
	
	if($^O eq 'MSWin32') {
		my $attrib;
		Win32::File::GetAttributes($filepath, $attrib) || die $!;
		Win32::File::SetAttributes($filepath, $attrib | READONLY) || die $!;
	} else {
		chmod((stat $filepath)[2] & 0555, $filepath);
	}
	
	return;
}

1;

__END__