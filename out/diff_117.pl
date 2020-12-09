#!/usr/bin/perl
use strict;

my ($n_cluster, $n_output) = @ARGV;
if (!$n_cluster or !$n_output) {
    die "Usage: $0 [n_cluster] [n_output]\n";
}

my @files = glob("extract-*");
my ($n,$count, @data);
foreach my $f (@files) {
    print "Loading $f ...\n";
    my ($idx, $added);
    open In, "$f" or die "Can't open $f: $!\n";
    while(<In>){
        if (/^Energy avg-0/) {
            $idx = 0;
        }
        elsif (defined $idx) {
            my @tlist = split /\s+/, $_;
            if (!$data[$idx]) {
                $n = @tlist;
                $data[$idx] = \@tlist;
            }
            elsif (abs($data[$idx]->[0] - $tlist[0]) > 0.001) {
                print "... Energy mismatch at line $idx\n";
                last;
            }
            else {
                for (my $i = 1; $i<$n; $i++) {
                    $data[$idx]->[$i] += $tlist[$i];
                }
                $added++;
            }
        }
    }
    close In;
    if ($added) {
        $count++;
    }
}

my @data_out;
foreach my $l (@data) {
    for (my $i = 1; $i<$n; $i++) {
        $l->[$i] /= $count;
    }
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
    push @data_out, [$l->[0], @l_out];
}

open Out, ">diff.txt" or die "Can't write diff.txt: $!\n";
print "  --> [diff.txt]\n";
print Out "Energy";
for (my $i = 0; $i<$n_output; $i++) {
    print Out " out-$i";
}
print Out "\n";

foreach my $l (@data_out) {
    print Out join(' ', @$l). "\n";
}
close Out;
