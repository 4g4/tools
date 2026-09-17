#!/usr/bin/env perl

use utf8;
use Encode;
use Path::Tiny;
use Getopt::Long;

my $dir_path = ".";
my $ext_name = 'pdf';
my $pattern = '';
my $dry_run = '';
my $zlib = '';
my $help = 0;

GetOptions (
  'dir=s' => \$dir_path,
  'ext=s' => \$ext_name,
  'pattern=s' => \$pattern,
  'dry' => \$dry_run,
  'zlib' => \$zlib,
  'help' => \$help,
) or die("Error in command line arguments\n");

if ($help) {
      print <<"HELP";
用法: $0 [选项]

选项:
  --dir=DIR       目标目录（默认: .）
  --ext=EXT       文件扩展名（默认: pdf，不带点）
  --pattern=PAT   要删除的字符串或正则表达式
  --dry           预览模式，不实际执行
  --zlib          Z-Library Pattern
  --help          显示此帮助

示例:
  $0 --pattern="abc" --dry
  $0 --pattern="def" --ext=mp4
HELP
  exit;
}

if ($zlib) {
  $pattern = " \(z-library.sk, 1lib.sk, z-lib.sk\)";
}

if (length $pattern == 0) {
  print "--pattern is required\n";
  exit;
}

my $dir = path($dir_path);
my $iter = $dir->iterator;

while (my $file = $iter->()) {
  next if $file->is_dir();
  my $basename = $file->basename;
  next unless $basename =~ /\.$ext_name$/i;

  my $parent = $file->parent;
  my $new_base = $basename;
  $new_base =~ s/$pattern//g;

  if ($basename ne $new_base) {
    my $new_file = $parent->child($new_base);
    if ($new_file->exists) {
      print("warning: $new_file exists, skip $basename\n");
      next;
    }

    if ($dry_run) {
      print("   $basename\n=> $new_base\n\n");
    } else {
      print("   $file\n=> $new_file\n\n");
      $file->move($new_file);
    }
  }
}
