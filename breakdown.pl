#!/usr/bin/perl
# Break down nbench results by benchmark, plus geomean.

use warnings;
use strict;
use Mean;

my @int_tests = ('NUMERIC SORT',
		 'STRING SORT',
		 'BITFIELD',
		 'FP EMULATION',
		 'ASSIGNMENT',
		 'IDEA',
		 'HUFFMAN');
my @fp_tests = ('FOURIER',
		'NEURAL NET',
		'LU DECOMPOSITION');
my @all_tests = (@int_tests, @fp_tests);

my @files = @ARGV;

my $res;

for (my $i = 0; $i < @files; $i++) {
    get_val($files[$i]);
}

my @titles = (@all_tests, 'gmean');
print join("\t", '# file\Bmark', map { $_, 'err' } @titles), "\n";
for (my $i = 0; $i < @files; $i++) {
    my $r = $res->{$files[$i]};
    print join("\t", $files[$i],
	       map { $r->{$_}->{val}, $r->{$_}->{err} } @titles
	), "\n";
}

sub get_val {
    my ($file) = @_;
    my $h;
    my $lastname;

    open my $in, '<:encoding(UTF-8)', $file or die "Could not open '$file' for reading $!";
    while (<$in>) {
	my $line = $_;

	chomp $line;

	if ($line =~ /(NUMERIC SORT|STRING SORT|BITFIELD|FP EMULATION|FOURIER|ASSIGNMENT|IDEA|HUFFMAN|NEURAL NET|LU DECOMPOSITION)/) {
	    my $name = $1;
	    if ($line =~ /^[^:]+:\s*[^:\s]+\s*:\s*([^:\s]+)\s*:/) {
		$lastname = $name;
		$h->{$name}->{val} = $1;
	    }
	}
	if ($line =~ /Relative standard deviation:\s*([^\s]*)/) {
	    die if !defined($lastname);
	    my $rel = $1 / 100.0;
	    $h->{$lastname}->{err} = $h->{$lastname}->{val} * $rel;
	}
    }
    close $in or die "Could not close '$file': $!";
    compute_geomean($h, \@all_tests);
    $res->{$file} = $h;
}

sub compute_geomean {
    my ($h, $tests) = @_;
    my @vals;
    my @errors;

    foreach (@$tests) {
	push @vals,   $h->{$_}->{val};
	push @errors, $h->{$_}->{err};
    }
    ($h->{gmean}->{val}, $h->{gmean}->{err}) = Mean::geometric_err(\@vals, \@errors);
}
