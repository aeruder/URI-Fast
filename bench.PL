#!perl

BEGIN{
  unless ($ENV{BENCH} || $ENV{UPDATEBENCH}) {
    print "Skipping benchmarks because neither BENCH nor UPDATEBENCH were set.\n";
    exit 0;
  }
};

use utf8;
use Benchmark qw(:all);
use URI::Fast qw(uri uri_split iri);
use URI::Encode::XS qw();
use URI::Escape qw();
use URL::Encode qw();
use URI::Split qw();
use URI;
use IRI;

my $POD;

if ($ENV{UPDATEBENCH} ) {
  print "Updating URI::Fast::Benchmarks\n";
  open $POD, '>', './lib/URI/Fast/Benchmarks.pod' or die $!;
} else {
  print "Running benchmarks\n";
  my $str = '';
  open $POD, '>', \$str or die $!;
}

print $POD q{# PODNAME: URI::Fast::Benchmarks
# ABSTRACT: Benchmarks comparing URI::Fast and URI

=head1 BENCHMARKS

Various operations comparing L<URI::Fast> against L<URI>'s performance. The
script to recreate is included in the C<bench> folder of the distribution.

Tests were performed on a Pixelbook (i5) using Termux and Perl 5.26 installed
with L<perlbrew|https://perlbrew.pl>. Earlier testing was done with a similarly
equipped MacBook Pro. It is interesting to note that URI::Fast's rate is
roughly the same, but URI's rate increased significantly over Perl compiled for
MacOS.

};

my @urls = (
  '/foo/bar/baz',
  'http://www.test.com',
  'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff',
  'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
  'https://www.çæ∂î∫∫å.com/ƒø∫∂é®?ƒøø=ßå®#ƒ®å©',
);

my $encode_input = "Ῥόδος¢€" . q{! * ' ( ) ; : @ & = + $ , / ? # [ ] %} x 10;
my $decode_input = URI::Fast::encode($encode_input);

sub test {
  my ($msg, $count, $tests) = @_;
  local $| = 1;

  print "> $msg\n";
  my $results = cmpthese $count, $tests;

  print $POD "=head2 $msg\n\n";

  foreach (@$results) {
    printf $POD "  %15s%15s%15s%15s\n", @$_;
  }

  print $POD "\n\n";

  print "\n";
}

test 'Constructor', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]) },
  'URI::Fast' => sub{ my $uri = uri $urls[3] },
};

test 'Parse scheme', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->scheme },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->scheme },
};

test 'Update scheme', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[1]); $uri->scheme('https') },
  'URI::Fast' => sub{ my $uri = uri $urls[1]; $uri->scheme('https') },
};

test 'Parse authorization', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->host },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->host },
};

test 'Update authorization', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->host('test.com') },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->host('test.com') },
};

test 'Parse path (scalar)', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my $p = $uri->path },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my $p = $uri->path },
};

test 'Parse path (list)', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my @p = $uri->path_segments },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my @p = $uri->path },
};

test 'Update path (scalar)', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->path('/foo/bar') },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->path('/foo/bar') },
};

test 'Update path (array)', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->path('/' . join('/', 'foo', 'bar')) },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->path(['foo', 'bar']) },
};

test 'Parse query', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my %q = $uri->query_form },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my @v = $uri->param('asdf') },
};

test 'Set query parameter', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); $uri->query_form(foo => 'bar') },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; $uri->param('foo', 'bar') },
};

test 'Query form', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my %q = $uri->query_form },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my $q = $uri->query_hash },
};

test 'Query keys', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my @k = keys %{$uri->query_form} },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my @k = $uri->query_keys },
};

test 'Stringification', 500_000, {
  'URI' => sub{ my $uri = URI->new($urls[3]); my $str = "$uri" },
  'URI::Fast' => sub{ my $uri = uri $urls[3]; my $str = "$uri" },
};

test 'uri_split', 1_000_000, {
  'URI::Split' => sub{ my @uri = URI::Split::uri_split($urls[3]) },
  'URI::Split' => sub{ my @uri = URI::Split::uri_split($urls[3]) },
  'URI::Fast' => sub{ my @uri = uri_split($urls[3]) },
};

test 'Encode', 1_000_000, {
  'URI::Escape' => sub{ URI::Escape::uri_escape_utf8($encode_input) },
  'URL::Encode' => sub{ URL::Encode::url_encode_utf8($encode_input) },
  'URI::Encode::XS' => sub{ URI::Encode::XS::uri_encode_utf8($encode_input) },
  'URI::Fast' => sub{ URI::Fast::encode($encode_input) },
};

test 'Decode', 1_000_000, {
  'URI::Escape' => sub{ URI::Escape::uri_unescape($decode_input) },
  'URL::Encode' => sub{ URL::Encode::url_decode_utf8($decode_input) },
  'URI::Encode::XS' => sub{ URI::Encode::XS::uri_decode_utf8($decode_input) },
  'URI::Fast' => sub{ URI::Fast::decode($decode_input) },
};

test 'IRI - ctor', 500_000, {
  'IRI'       => sub{ my $iri = IRI->new($urls[4]) },
  'URI::Fast' => sub{ my $iri = iri $urls[4] },
};

test 'IRI - query_hash', 500_000, {
  'IRI' => sub{ my $iri = IRI->new($urls[4]); my %q = $iri->query_form },
  'URI::Fast' => sub{ my $iri = iri $urls[4]; my $q = $iri->query_hash },
};

test 'IRI - set param', 500_000, {
  'IRI' => sub{ my $iri = IRI->new($urls[4]); $iri->query_form('ßåΩ' => 'ßå†') },
  'URI::Fast' => sub{ my $iri = iri $urls[4]; $iri->param('ßåΩ', 'ßå†') },
};

test 'IRI - update path', 500_000, {
  'IRI' => sub{ my $iri = IRI->new($urls[4]); $iri->path('/Ῥόδος¢€') },
  'URI::Fast' => sub{ my $iri = iri $urls[4]; $iri->path('/Ῥόδος¢€') },
};

close $POD;
