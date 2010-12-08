#! /usr/bin/perl -w

# The contents of this file are dedicated to the public domain. To the extent
# that dedication to the public domain is not available, everyone is granted a
# worldwide, perpetual, royalty-free, non-exclusive license to exercise all
# rights associated with the contents of this file for any purpose whatsoever.
# No rights are reserved.

use strict;
use WWW::Mechanize;
use HTTP::Cookies::Netscape;
use HTML::TokeParser;
use Data::Dumper;
use Getopt::Long;
use Term::ReadKey;

my ($user, $password, $dept, $help, $debug);
$dept = "CS";
my $result = GetOptions ("user=s" => \$user,
                         "password=s"   => \$password,
                         "dept=s"   => \$dept,
                         "debugquick" => \$debug,
                         "help"  => \$help);

if (defined $help) {
  print "Usage: $0 --user username [--dept department --password password --help --debugquick]\n";
  print 
    "The list of URLs is printed to STDOUT.\n".
    "A password will be prompted for if none is supplied with -p.\n".
    "--debugquick will make it get a single video link quickly to see if it works.\n".
    "--dept defaults to CS\n" ;
  exit 1;
}

if(!defined $password) {
  print STDERR "Password:";
  ReadMode 'noecho';
  $password = ReadLine 0;
  chomp $password;
  ReadMode 'normal';
  print STDERR "\n";
}

my $cookie_jar = HTTP::Cookies->new(); 

my $m = WWW::Mechanize->new();
$m->cookie_jar($cookie_jar);
$m->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.X.Y.Z Safari/525.13');


my $url = 'https://myvideosu.stanford.edu/oce/currentquarter.aspx';

$m->get($url);

$m->form_name('login');
$m->field(username => $user);
$m->field(password => $password);
$m->click();


my @courses = $m->
  find_all_links(
                 url_regex => qr/OCE.*course=$dept.*/,
                );

my (@classes, @videos);
foreach my $course (@courses) {
  $m->get($course->url());
  my @cvideos = $m->
    find_all_links(
                   url_regex => qr/wmp=true/,
                  );
  foreach (@cvideos) {
    my $url = $_->url();
    $url =~ s/.*\'(.*wmp=true).*/$1/;
    push (@classes, $url);
    last if (defined $debug);
  }
}

foreach my $class_url (@classes) {
  $m->get($class_url);
  my $parser = HTML::TokeParser->new(\$m->content());
  my $token = $parser->get_tag( "object" );
  my $attrs = $token->[1];
  my $cobb_link = $attrs->{data};
  print "$cobb_link\n";
  push (@videos, $cobb_link);
  last if (defined $debug);
}
