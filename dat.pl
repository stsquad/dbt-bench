#!/usr/bin/perl

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

my @vers = map { (my $s = $_) =~ s/\.nbench$//; $s } @ARGV;
die if (!@vers);

my $res;
my $arch;

foreach my $ver (@vers) {
    get_val($ver);
}

print "# versions: ", join("\t", @vers), "\n";
print "# arch: $arch\n";
for (my $i = 0; $i < @vers; $i++) {
    my $r = $res->{$vers[$i]};
    print join("\t", $i,
	       $r->{int}->{gmean}, $r->{int}->{err},
	       $r->{fp}->{gmean},  $r->{fp}->{err}
    ), "\n";
}

sub get_val {
    my ($ver) = @_;
    my $file = "$ver.nbench";
    my $r;
    my $s;
    my $h;
    my @avgs = ();
    my @errors = ();
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
	    $h->{$lastname}->{rel_err} = $1 / 100.0;
	}
	if ($line =~ /dbt-bench: arch: (\w+)/) {
	    my $a = $1;
	    if (!defined($arch)) {
		$arch = $a;
	    }
	    if ($a ne $arch) {
		die "architecture '$a' in file '$file' does not match that in previous files ('$arch'). Stopped";
	    }
	}
    }
    close $in or die "Could not close '$file': $!";

    grab_results($ver, 'int', $h, \@int_tests);
    grab_results($ver, 'fp', $h, \@fp_tests);
}

sub grab_results {
    my ($ver, $type, $h, $tests) = @_;
    my @vals;
    my @errors;

    foreach (@$tests) {
	push @vals,   $h->{$_}->{val} || die;
	push @errors, $h->{$_}->{val} * $h->{$_}->{rel_err} || die;
    }
    my ($gmean, $err) = Mean::geometric_err(\@vals, \@errors);
    $res->{$ver}->{$type}->{gmean} = $gmean;
    $res->{$ver}->{$type}->{err}   = $err;
}