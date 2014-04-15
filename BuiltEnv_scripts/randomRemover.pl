#!/usr/bin/perl
# Script: randomRemover.pl
# Description: Randomly removes data from Qiime Databases 
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 04.10.2014
##################################
use warnings;
use strict;
use lib '/rhome/sahrendt/Scripts';
use Getopt::Long;
use SeqAnalysis;
use Bio::Seq;
use Bio::SeqIO;

#####-----Global Variables-----#####
my $input;
my $db_path = "/rhome/sahrendt/bigdata/Built_Env/dbs";
my $seqout_filename; # output file w/ random data removed
my $rem_thresh = 0.2; # percentage of original data to remove
my %rand_keys;
my ($accnos_file,@accnos);  # list of accesion numbers
my ($fasta_file, $fasta_filename);
my $tax_file;
my ($help,$verb);

GetOptions ('i|input=s' => \$input,
            'h|help'   => \$help,
            'v|verbose' => \$verb);
my $usage = "Usage: randomRemover.pl -i database_dir\n";
die $usage if $help;
die "No input.\n$usage" if (!$input);

#####-----Main-----#####
## Get original accnos, taxonomy, and fasta files
opendir(DB,"$db_path/$input");
$accnos_file = (grep { /\.accnos$/ } readdir(DB))[0];
closedir(DB);

opendir(DB,"$db_path/$input");
$fasta_file = (grep { /\.fasta$/ } readdir(DB))[0];
closedir(DB);

opendir(DB,"$db_path/$input");
$tax_file = (grep { /\.txt$/ } readdir(DB))[0];
closedir(DB);

die "No accnosfile found\n" if (!$accnos_file);
die "No fastafile found\n" if (!$fasta_file);
die "No taxfile found\n" if (!$tax_file);

warn $accnos_file if $verb;
warn $fasta_file if $verb;
warn $tax_file if $verb;

my @tmp = split(/\./,$fasta_file);
pop @tmp;
$fasta_filename = join(".",@tmp);
$seqout_filename = join("_",$fasta_filename,"RR");

warn $seqout_filename if $verb;

## Set accnos as array to pick random indices
open(my $acc_fh, "<", $accnos_file) or die "Can't open $accnos_file: $!\n";
@accnos = <$acc_fh>;
chomp @accnos;
close($acc_fh);

for(my $i=0; $i<($rem_thresh*scalar(@accnos)); $i++)
{

  my $rand_ind = int(rand(scalar(@accnos)));
  while(exists $rand_keys{$rand_ind})
  {
    $rand_ind = int(rand(scalar(@accnos)));
  }
  $rand_keys{$rand_ind} = $accnos[$rand_ind];
  if($verb){warn "$i out of ",scalar(@accnos),"($rand_ind)\n";}
}

## Use random accnos to delete from fasta and taxonomy files
my %fasta = indexFasta("$db_path/$input/$fasta_file");
foreach my $del_key (keys %rand_keys)
{
  warn "$rand_keys{$del_key}\n" if $verb;
  delete $fasta{$rand_keys{$del_key}};
  delete $tax{$rand_keys{$del_key}};
}

## Write the remaining sequences & generate new accnos file
my $fasta_out = Bio::SeqIO->new(-file => ">$seqout_filename\.fasta",
                                -format => "fasta");
foreach my $key (sort keys %fasta)
{
  $fasta_out->write_seq($fasta{$key});
}

print `getaccnos.pl -i $seqout_filename\.fasta > $seqout_filename\.accnos`;

## Write new taxonomy file

warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
