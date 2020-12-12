#!/usr/bin/perl
use strict;

my $file = $ARGV[0];
if (!-e $file) {
    die "Usage: $0 [input_data_file]";
}

if (!-d "extract") {
    mkdir "extract" or die "Can't mkdir extract.\n";
}

my ($i_energy, $i_c0, $i_c1, $i_c2, $n_repeat, $n_trigger);
my ($i_Sa);

my @out;
my $i_data;
open In, "$file" or die "Can't open $file: $!\n";
while(<In>){
    if (/^#L\s+N\s+Epoch\s+Energy/) {
        my @tlist = split /\s+/, $_;
        my $i=-1;
        foreach my $a (@tlist) {
            if ($a eq "Energy") {
                $i_energy = $i;
            }
            elsif ($a eq "c0o0b0") {
                $i_c0 = $i;
            }
            elsif ($a eq "c1o0b0") {
                $i_c1 = $i;
            }
            elsif ($a eq "c2o0b0") {
                $i_c2 = $i;
            }
            elsif ($a eq "c0o1b0") {
                $n_trigger = $i - $i_c0;
            }
            elsif ($a eq "Sa") {
                $i_Sa = $i;
            }
            $i++;
        }
        $n_repeat = int(($i_c1 - $i_c0) / $n_trigger);
        my $d1 = $i_c1 - $i_c0;
        my $d2 = $i_c2 - $i_c1;
        $i_c0 -= 3;
        $i_c1 -= 3;
        $i_c2 -= 3;
        print "energy at $i_energy, (c0, c1, c2) = ($i_c0, +$d1, +$d2), $n_trigger, $n_repeat\n";
    }
    elsif (/^\d+/ and $i_energy) {
        my @tlist = split /\s+/;
        $i_data++;
        my $n = @tlist;
        my $energy = $tlist[$i_energy];
        my (@c0_data, @c0_count);
        for (my $i = $i_c0; $i<$i_c1; $i++) {
            my $j = ($i-$i_c0) % 9;
            $c0_data[$j]+=$tlist[$i];
            $c0_count[$j]++;
        }
        for (my $j = 0; $j<9; $j++) {
            $c0_data[$j] /= $c0_count[$j];
        }
        my @data;
        for (my $j = 0; $j<$n_trigger; $j++) {
            my $cnt = $n_repeat;
            if ($i_c0 + $n_repeat * $n_trigger + $j < $i_c1) {
                $cnt++;
            }
            my $sum1;
            for (my $i = 0; $i<$cnt; $i++) {
                my $off=$i*$n_trigger+$j;
                my $c0 = $c0_data[$off % 9];
                my $c1 = $tlist[$i_c1 + $off];
                my $c2 = $tlist[$i_c2 + $off];
                my $c = ($c1 + $c2) / 2 /$c0;
                $sum1 += $c;
            }
            $sum1 /= $cnt;
            $data[$j] = $sum1;
        }
        print "  energy = $energy, \t$n points\n";
        push @out, [$energy, @data];
    }
}
close In;

if (!-d "extract") {
    mkdir "extract";
}
open Out, ">extract/extract-$file" or die "Can't write extract/extract-$file: $!\n";
print "  --> [extract/extract-$file]\n";
my @header = ("Energy");
for (my $i = 0; $i<$n_trigger; $i++) {
    push @header, "avg-$i";
}
print Out join(' ', @header)."\n";

foreach my $d (@out) {
    print Out join(' ', @$d)."\n";
}
close Out;
