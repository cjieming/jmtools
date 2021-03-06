#!/usr/bin/perl

use warnings;
use strict;

if (scalar(@ARGV) == 0) {
    print "The program checks map files for obvious inconsistencies.\n";
    exit;
}

my $file = "";
foreach $file (@ARGV) {
    if (!open(FILE,$file)) {
	print STDERR "Can't open file '",$file,"'.\n";
	next;
    }
    my @blocks = ();
    my $n = -1;
    while (my $line = <FILE>) {
	if (substr($line,0,1) eq "#") { next; }
	my @tmp = split(/\s+/,$line);
	if ($n < 0) { $n = scalar(@tmp); }
	elsif ($n != scalar(@tmp)) {
	    print $file,": different number (",$n,
	    print " ",scalar(@tmp),") of haplotypes at:\n";
	    print $line;
	    last;
	}
	push(@blocks,\@tmp);
    }
    close(FILE);

    my $nb = scalar(@blocks);
    for (my $b = 0;$b < $nb;$b++) {
	my $curr = $blocks[$b];
	my ($delta,$ind) = (0,$b + 1);
	while ($delta == 0 && $ind < $nb) {
	    $delta = getDelta($curr,$blocks[$ind],$n);
	    $ind++;
	}
	push(@$curr,$delta);
    }

    my $curr = $blocks[0];
    my @coor = (@$curr);
    my $len = $$curr[$n];
    for (my $b = 1;$b < $nb;$b++) {
	for (my $i = 0;$i < $n;$i++) {
	    if ($$curr[$i] > 0) { $coor[$i] += $len; }
	}
	$curr = $blocks[$b];
	for (my $i = 0;$i < $n;$i++) {
	    if ($$curr[$i] > 0 && $coor[$i] != $$curr[$i]) {
		print $file,": inconsistency around:\n";
		printError($file,$blocks[$b - 1],$curr);
		printError($file,\@coor,$curr);
	    }
	}
	$len = $$curr[$n];
    }
}

exit;

sub getDelta
{
    my ($arr1,$arr2,$n) = @_;
    my $delta = 0;
    for (my $i = 0;$i < $n;$i++) {
	if ($$arr1[$i] == 0 || $$arr2[$i] == 0) { next; }
	my $d = $$arr2[$i] - $$arr1[$i];
	if ($d <= 0) {
	    print $file,": bad block size:\n";
	    printError($file,$arr1,$arr2);
	} elsif ($delta <= 0) {
	    $delta = $d;
	} elsif ($delta != $d) {
	    print $file,": inconsistency in block size:\n";
	    printError($file,$arr1,$arr2);
	}
    }
    return $delta;
}

sub hasDeletion
{
    my $arr = shift;
    for (my $i = 0;$i < 3;$i++) {
	if ($$arr[$i] == 0) { return 1; }
    }
    return 0;
}

sub printError
{
    my ($file,$arr1,$arr2) = @_;
    for (my $i = 0;$i < 3;$i++) { print $$arr1[$i]," "; }
    print "\n";
    for (my $i = 0;$i < 3;$i++) { print $$arr2[$i]," "; }
    print "\n";
}
