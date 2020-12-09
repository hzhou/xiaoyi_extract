#!/usr/bin/perl
use strict;

my ($file, $n_cluster, $n_output) = @ARGV;
if (!-f $file or !$n_cluster or !$n_output) {
    die "Usage: $0 $file n_cluster n_output\n";
}

my @data_out;
print "Loading $file ...\n";
my $flag;
open In, "$file" or die "Can't open $file: $!\n";
while(<In>){
    if (/^Energy avg-0/) {
        $flag = 1;
    }
    elsif ($flag) {
        my @tlist = split /\s+/, $_;
        push @data_out, get_diff(\@tlist, $n_cluster, $n_output);
    }
}
close In;

open Out, ">diff-out.txt" or die "Can't write diff-out.txt: $!\n";
print "  --> [diff-out.txt]\n";
foreach my $l (@data_out) {
    print Out join(' ', @$l). "\n";
}
close Out;

# ---- subroutines --------------------------------------------
sub get_diff {
    my ($l, $n_cluster, $n_output) = @_;
    my @ground;
    for (my $i = 1; $i<27; $i++) {
        my $j = ($i) % 9;
        if ($i+18>=26) {
            $ground[$j] = ($l->[$i] + $l->[$i+9] + $l->[$i+18]) / 3;
        }
        else {
            $ground[$j] = ($l->[$i] + $l->[$i+9]) / 2;
        }
    }

    my $n = @$l;
    for (my $i = 27; $i<$n; $i++) {
        my $j = ($i) % 9;
        $l->[$i] -= $ground[$j];
    }

    my @l_out;
    my $i = 27;
    for (my $i_out = 0; $i_out<$n_output; $i_out++) {
        my $sum;
        for (my $i_c = 0; $i_c<$n_cluster; $i_c++) {
            $sum += $l->[$i];
            $i++;
        }
        push @l_out, $sum/$n_cluster;
    }
    return [$l->[0], @l_out];
}

