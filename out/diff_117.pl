#!/usr/bin/perl
use strict;

our $trigger = 26;


my ($file, $n_cluster, $n_output) = @ARGV;
if (!-f $file or !$n_cluster or !$n_output) {
    die "Usage: $0 $file n_cluster n_output\n";
}

my @data_out;
push @data_out, get_header($n_output);

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
sub get_header {
    my ($n_output) = @_;
    my @tlist = "Energy";
    for (my $i = 0; $i<$n_output; $i++) {
        push @tlist, " avg-$i";
    }
    for (my $i = 0; $i<$n_output; $i++) {
        push @tlist, " diff-$i";
    }
    return  \@tlist;
}

sub get_diff {
    my ($l, $n_cluster, $n_output) = @_;
    my $energy = shift @$l;
    my (@ground, @counters);
    for (my $i = 0; $i<$trigger; $i++) {
        my $j = $i % 9;
        $ground[$j] += $l->[$i];
        $counters[$j]++;
    }
    for (my $j = 0; $j<9; $j++) {
        $ground[$j] /= $counters[$j];
    }
    my @l_avg;
    my $i = $trigger;
    for (my $i_out = 0; $i_out<$n_output; $i_out++) {
        my $sum;
        for (my $i_c = 0; $i_c<$n_cluster; $i_c++) {
            $sum += $l->[$i];
            $i++;
        }
        push @l_avg, $sum/$n_cluster;
    }

    my $n = @$l;
    for (my $i = $trigger; $i<$n; $i++) {
        my $j = ($i) % 9;
        $l->[$i] -= $ground[$j];
    }

    my @l_diff;
    my $i = $trigger;
    for (my $i_out = 0; $i_out<$n_output; $i_out++) {
        my $sum;
        for (my $i_c = 0; $i_c<$n_cluster; $i_c++) {
            $sum += $l->[$i];
            $i++;
        }
        push @l_diff, $sum/$n_cluster;
    }

    return [$energy, @l_avg, @l_diff];
}

