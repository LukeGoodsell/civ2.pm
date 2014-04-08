package civ2;


# Dependencies
use strict;
use warnings;
use base 'Exporter';
use Fcntl qw(:seek);
use File::chmod;
use Time::localtime;
use Win32::File;
use POSIX qw(floor);
use civ2::filenames;


# Subroutine declarations
sub read_file_hexdata_at_offset($$$);
sub get_savegame_difficulty($);
sub get_savegame_turn_number($);
sub read_savegame_settings($);
sub adbc_to_intyear($);
sub intyear_to_adbc($);
sub intyear_to_turnno($$);
sub turnno_to_intyear($$);
sub turnno_to_year($$);
sub year_to_turnno($$);
sub make_file_readonly($);


# Module info
our $VERSION = '0.02';
our @EXPORT = qw(
	read_savegame_settings
	make_file_readonly
	turnno_to_year
	year_to_turnno
);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = qw();


# Global data
use constant {
	DIFFICULTY_CHIEFTAIN	=> 'Chieftain',
	DIFFICULTY_WARLORD		=> 'Warlord',
	DIFFICULTY_PRINCE		=> 'Prince',
	DIFFICULTY_KING			=> 'King',
	DIFFICULTY_EMPEROR		=> 'Emperor',
	DIFFICULTY_DEITY		=> 'Deity',
};

our @difficulties_asc = (
	DIFFICULTY_CHIEFTAIN,
	DIFFICULTY_WARLORD,
	DIFFICULTY_PRINCE,
	DIFFICULTY_KING,
	DIFFICULTY_EMPEROR,
	DIFFICULTY_DEITY
);

our $difficulty_adbc_yearsperturn = {
	&DIFFICULTY_PRINCE	=> {
		'4000BC' 	=> 20,
		'1AD'		=> 19,
		'20AD'		=> 20,
		'1000AD'	=> 10,
		'1500AD'	=> 5,
		'1750AD'	=> 2,
		'1850AD'	=> 1,
	},
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

# Validation check:
foreach my $test_difficulty (keys(%{ $difficulty_intyear_yearsperturn })) {
	for(my $testturn = 1; $testturn < 1000; $testturn++) {
		my $testyear = turnno_to_year($testturn, $test_difficulty);
		my $testturnback = year_to_turnno($testyear, $test_difficulty);
		if($testturn != $testturnback) {
			die "Error for turn '$testturn': $testyear, $testturnback, $test_difficulty";
		}
	}
}


# Subroutines

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
	my ($intyear, $difficulty) = @_;
	
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
	
	return floor($turnno);
}

sub turnno_to_intyear($$) {
	my ($turnno, $difficulty) = @_;
	
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

sub turnno_to_year($$) {
	my ($turnno, $difficulty) = @_;
	return intyear_to_adbc(turnno_to_intyear($turnno, $difficulty));
}

sub year_to_turnno($$) {
	my ($year, $difficulty) = @_;
	return intyear_to_turnno(adbc_to_intyear($year), $difficulty);
}

sub read_savegame_settings($) {
	my ($filepath) = @_;
	my $settings = {};
	
	{
		my $byte15 = ord(read_file_hexdata_at_offset($filepath, 15, 1));
	
		$settings->{cheat_menu} 					= ($byte15 & 128 ? 1 : 0);
		$settings->{always_wait_at_end_of_turn} 	= ($byte15 & 64 ? 1 : 0);
		$settings->{autosave_each_turn} 			= ($byte15 & 32 ? 1 : 0);
		$settings->{show_enemy_moves} 				= ($byte15 & 16 ? 1 : 0);
		$settings->{no_pause_after_enemy_moves} 	= ($byte15 & 8 ? 1 : 0);
		$settings->{fast_piece_slide} 				= ($byte15 & 4 ? 1 : 0);
		$settings->{instant_advice} 				= ($byte15 & 2 ? 1 : 0);
		$settings->{tutorial_help} 					= ($byte15 & 1 ? 1 : 0);
	}
	
	{
		my $byte20 = ord(read_file_hexdata_at_offset($filepath, 20, 1));
	
		$settings->{scenario_flag}					= ($byte20 & 128 ? 1 : 0);
		$settings->{scenario_file}				 	= ($byte20 & 64 ? 1 : 0);
		$settings->{byte20_32}						= ($byte20 & 32 ? 1 : 0);
		$settings->{cheat_penalty}		 			= ($byte20 & 16 ? 1 : 0);
		$settings->{byte20_8} 						= ($byte20 & 8 ? 1 : 0);
		$settings->{byte20_4} 						= ($byte20 & 4 ? 1 : 0);
		$settings->{byte20_2} 						= ($byte20 & 2 ? 1 : 0);
		$settings->{byte20_1} 						= ($byte20 & 1 ? 1 : 0);
	}
	
	$settings->{turn_number} = unpack("S", read_file_hexdata_at_offset($filepath, 28, 2) );
	defined($settings->{turn_number}) or die "No turn number";
	
	{
		my $byte44 = ord(read_file_hexdata_at_offset($filepath, 44, 1));
		
		defined($byte44) or die "No difficulty num";
		   if($byte44 == 0) { $settings->{difficulty} = DIFFICULTY_CHIEFTAIN; }
		elsif($byte44 == 1) { $settings->{difficulty} = DIFFICULTY_WARLORD; }
		elsif($byte44 == 2) { $settings->{difficulty} = DIFFICULTY_PRINCE; }
		elsif($byte44 == 3) { $settings->{difficulty} = DIFFICULTY_KING; }
		elsif($byte44 == 4) { $settings->{difficulty} = DIFFICULTY_EMPEROR; }
		elsif($byte44 == 5) { $settings->{difficulty} = DIFFICULTY_DEITY; }
		else { die "Uknown difficulty: '$byte44'"; }
	}
	
	
	return $settings;
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