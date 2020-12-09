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

my @out;
open In, "$file" or die "Can't open $file: $!\n";
while(<In>){
    if (/^#L\s+N\s+Epoch\s+Energy/) {
        my @tlist = split /\s+/, $_;
        my $i = -1;
        foreach my $a (@tlist) {
            $i++;
            if ($a eq "Energy") {
                $i_energy = $i - 1;
            }
            elsif ($a eq "c0o0b0") {
                $i_c0 = $i - 1;
            }
            elsif ($a eq "c1o0b0") {
                $i_c1 = $i - 1;
            }
            elsif ($a eq "c2o0b0") {
                $i_c2 = $i - 1;
            }
            elsif ($a eq "c0o1b0") {
                $n_trigger = ($i - 1) - $i_c0;
            }
        }
        $n_repeat = int(($i_c1 - $i_c0) / $n_trigger);
        print "$i_energy, $i_c0, $n_trigger, $n_repeat\n";
    }
    elsif (/^\d+/ and $i_energy) {
        my @tlist = split /\s+/;
        my $energy = $tlist[$i_energy];
        print "  energy = $energy...\n";
        my (@data, @data2);
        for (my $j = 0; $j<$n_trigger; $j++) {
            my ($sum1, $sum2);
            for (my $i = 0; $i<$n_repeat; $i++) {
                my $c0 = $tlist[$i_c0 + $i * $n_trigger + $j];
                my $c1 = $tlist[$i_c1 + $i * $n_trigger + $j];
                my $c2 = $tlist[$i_c2 + $i * $n_trigger + $j];
                my $c = ($c1 + $c2) / $c0;
                $sum1 += $c;
                $sum2 += $c * $c;
            }
            $sum1 /= $n_repeat;
            $sum2 /= $n_repeat;
            $sum2 = sqrt($sum2 - ($sum1 * $sum1));
            $data[$j] = $sum1;
            $data2[$j] = $sum2;
        }
        push @out, [$energy, @data];
    }
}
close In;

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
