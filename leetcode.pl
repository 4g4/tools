#!/usr/bin/env perl

use utf8;
use Encode;
use strict;
use Getopt::Long;
use Path::Tiny;
use JSON::PP;

my $file = '';
my $output_file = '';

GetOptions (
  'input=s' => \$file,
  'output=s' => \$output_file,
) or die("Error in command line arguments\n");

if (length $file == 0) {
  print "--file is required\n";
  exit;
}

my $f = path($file);
my @contents = $f->lines_utf8({chomp => 1});

sub trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}

sub parse_1d_array {
  my $array = shift;
  my @output;
  push @output, scalar(@$array);
  push @output, join(' ', @$array);
  return join("\n", @output);
}

sub parse_2d_array {
  my $array = shift;
  my @output;
  my $rows = scalar(@$array);
  my $cols = scalar(@{$array->[0]}) if $rows > 0;

  push @output, "$rows $cols";
  foreach my $row (@$array) {
    push @output, join(' ', @$row);
  }
  return join("\n", @output);
}

sub parse_string {
  my $str = shift;
  $str =~ s/^["']|["']$//g;
  return $str;
}

sub parse_single_input {
  my $input = shift;
  $input = trim $input;

  my ($var, $value) = $input =~ /^\s*(\w+)\s*=\s*(.*)$/;

  die "Can't parse input: $input" unless defined $value;

  if ($value =~ /^\[.*\]$/) {
    # array
    my $json = JSON::PP->new;
    my $data = $json->decode($value);

    if (ref $data eq 'ARRAY') {
      if (@$data && ref $data->[0] eq 'ARRAY') {
        return parse_2d_array($data);
      } else {
        return parse_1d_array($data);
      }
    }
  } elsif ($value =~ /^".*"$/ || $value =~ /^'.*'$/) {
    # string
    return parse_string($value);
  } elsif ($value =~ /^-?\d+$/) {
    # integer  
    return $value;
  } else {
    die "Can't parse value: $value";  
  }
}

sub parse_input {
  my $line = shift;
  my @items = split(/, /, $line);
  my @output;
  for my $item (@items) {
    push @output, parse_single_input($item);
  }
  return join("\n", @output) . "\n";
}

sub write_json_file {
  my ($data, $filename) = @_;
  my $json = JSON::PP->new;
  $json->pretty(1);
  $json->utf8(1);
  my $json_text = $json->encode($data);
  my $file = path($filename);
  $file->spew_utf8($json_text);
}

my @inputs;

for my $line (@contents) {
  my @patterns = ("Input: ", "输入：");

  for my $input_pattern (@patterns) {
    if ($line =~ m/$input_pattern/) {
      $line =~ s/$input_pattern//g;
      $line = trim $line;
      push @inputs, {
        "test" => parse_input($line)
      };
    }
  }
}

$output_file = $output_file . "__tests";
write_json_file(\@inputs, $output_file);
