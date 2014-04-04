package civ2::debug;


# Dependencies
use strict;
use warnings;
use base 'Exporter';
use Sort::Naturally;


# Subroutine declarations
sub ref_definition($;$);
sub var_definition;
sub printvar($@);

# Module info
our $VERSION = '0.02';
our @EXPORT = qw(
	printvar
);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = qw();


# Subroutines
sub ref_definition($;$) {
	my $variable = shift;
	my $indent_level = 0;
	if(scalar(@_) > 0) { $indent_level = shift; }
	
	defined($variable) or return 'undef';
	
	my $returnval;
	my $reftype = ref($variable);
	
	if($reftype eq 'CODE') {
		
		$returnval = 'CODE';
		
	} elsif($reftype eq 'SCALAR') {
		
		$returnval = $$variable;
		
	} elsif($reftype eq 'ARRAY') {
		
		$returnval = "[";
		$indent_level++;
		my $first = 1;
		foreach my $subvar (@{$variable}) {
			if($first) {
				undef($first);
			} else {
				$returnval .= ',';
			}
			$returnval .= "\n";
			$returnval .= "\t" x $indent_level;
			$returnval .= ref_definition($subvar, $indent_level);
		}
		$returnval .= "\n";
		$indent_level--;
		$returnval .= "\t" x $indent_level;
		$returnval .= "]";
		
	} elsif($reftype eq 'HASH') {
		
		$returnval = "{";
		$indent_level++;
		my $first = 1;
		foreach my $key (nsort(keys(%{$variable}))) {
			if($first) {
				undef($first);
			} else {
				$returnval .= ',';
			}
			$returnval .= "\n";
			$returnval .= "\t" x $indent_level;
			$returnval .= "'$key' => ";
			$returnval .= ref_definition($variable->{$key}, $indent_level);
		}
		$returnval .= "\n";
		$indent_level--;
		$returnval .= "\t" x $indent_level;
		$returnval .= "}";
		
	} elsif($reftype eq 'REF') {
		
		$returnval = ref_definition($$variable, $indent_level);
		
	} elsif($reftype eq '') {
		
		$returnval = "'$variable'";
		
	} else {
		warn "Unhandled reftype: $reftype";
		$returnval = $variable;
	}
	
	return $returnval;
}

sub var_definition {
	my $returnval;
	
	if(scalar(@_) == 1) {
		
		$returnval = ref_definition($_[0]);
		
	} elsif(scalar(@_) > 1) {
		
		$returnval = '(';
		my $first = 1;
		foreach my $subvar (@_) {
			if($first) {
				undef($first);
			} else {
				$returnval .= ',';
			}
			$returnval .= "\n\t";
			$returnval .= ref_definition($subvar, 1);
		}
		$returnval .= "\n)";
		
	} else {
		$returnval = 'undef';
	}
	return $returnval;
}

sub printvar($@) {
	my $name = shift;
	my @var = @_;
	
	print "$name = ";
	
	print var_definition(@var);
	
	print ";\n";
	
	return;
}




1;