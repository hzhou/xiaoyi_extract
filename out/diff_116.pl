#!/usr/bin/perl
use strict;

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
    my @counts;
    my @ground;
    my $trigger=11;
    for (my $i = 0; $i<8; $i++) {
        my $i_t = $trigger + 116 * $i;
        for (my $k = 0; $k<18; $k++) {
            my $k2 = ($i_t - $k - 1 + 927) % 927;
            my $j = $k2 % 9;
            $ground[$j] += $l->[$k2 + 1];
            $counts[$j] ++;
        }
    }
    for (my $j = 0; $j<9; $j++) {
        $ground[$j] /= $counts[$j];
    }
    my (@data, @diff);
    for (my $i = 0; $i<8; $i++) {
        for (my $j = 0; $j<116; $j++) {
            my $idx = $trigger + $i * 116 + $j;
            push @data, $l->[$idx + 1];
            push @diff, $l->[$idx + 1] - $ground[$idx % 9];
        }
    }
    my @l_data;
    my $i = 0;
    for (my $i_out = 0; $i_out<$n_output; $i_out++) {
        my $sum;
        for (my $i_c = 0; $i_c<$n_cluster; $i_c++) {
            $sum += $data[$i];
            $i++;
        }
        push @l_data, $sum/$n_cluster;
    }
    my @l_diff;
    my $i = 0;
    for (my $i_out = 0; $i_out<$n_output; $i_out++) {
        my $sum;
        for (my $i_c = 0; $i_c<$n_cluster; $i_c++) {
            $sum += $diff[$i];
            $i++;
        }
        push @l_diff, $sum/$n_cluster;
    }
    return [$l->[0], @l_data, @l_diff];
}

