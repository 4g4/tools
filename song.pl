#!/usr/bin/env perl

use utf8;
use warnings;
use strict;
use Path::Tiny;
use Getopt::Long;
use Audio::FLAC::Header;
use Encode;
use File::Spec;
use File::HomeDir;
use File::Path qw(make_path);

my $dir_path = ".";
my $dry_run = '';
my $help = 0;
my $target_dir = File::Spec->catfile(home(), "Music/PopMusic/");

GetOptions (
  'dir=s' => \$dir_path,
  'dry' => \$dry_run,
  'help' => \$help,
  'target=s' => \$target_dir,
) or die("Error in command line arguments\n");

if ($help) {
      print <<"HELP";
用法: $0 [选项]

选项:
  --dir=DIR       源目录（默认: .）
  --target=DIR    目标目录（默认：~/Music/PopMusic/）
  --dry           预览模式，不实际执行
  --help          显示此帮助

示例:
  $0 --dry
HELP
  exit;
}

unless (-d $target_dir) {
  print "Creating target dir: $target_dir\n";
  if (! $dry_run) {
    make_path($target_dir);
  }
}

my $dir = path($dir_path);
my $iter = $dir->iterator;

while (my $file = $iter->()) {
  next if $file->is_dir();
  my $basename = $file->basename;
  next unless $basename =~ /.*\.flac/i;

  my $flac = Audio::FLAC::Header->new($file);
  my $tags = $flac->tags();
  my $title = $tags->{TITLE} || '';
  my $artist = $tags->{ARTIST} || '';

  $title =~ s/^\s+|\s+$//g;
  $artist =~ s/^\s+|\s+$//g;

  if (!$title || !$artist) {
    warn "skip $file: missing TITLE or ARTIST tag";
    next;
  }

  my $clean_title = $title;
  $clean_title =~ s/[\/\\:*?"<>|]/_/g;
  my $clean_artist = $artist;
  $clean_artist =~ s/[\/\\:*?"<>|]/_/g;

  my $new_name = "$clean_title-$clean_artist.flac";
  my $dest = File::Spec->catfile($target_dir, $new_name);

  if (-e $dest) {
    warn "$dest already exists!";
    next;
  }

  if ($dry_run) {
    print "   $file\n=> $dest\n\n";
  } else {
    print "   $file\n=> $dest\n\n";
    $file->move($dest);
  }
}

