#!perl

BEGIN{
  unless ($ENV{BENCHINTERNALS}) {
    print "Skipping internals benchmarks because BENCHINTERNALS was not set.\n";
    exit 0;
  }
};

use URI::Fast qw(uri uri_split);
use Benchmark qw(:all);
use URI;

my $url = 'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&baz=bar&asdf=the+quick%20brown+fox+%26+hound#foofrag';

timethese 1_000_000, {
 'ctor               ' => sub{ my $u = uri $url },
 'get: scheme        ' => sub{ my $u = uri($url)->scheme },
 'set: scheme        ' => sub{ uri($url)->scheme('http') },
 'get: auth          ' => sub{ my $u = uri($url)->host },
 'set: auth          ' => sub{ uri($url)->host('www.test.com') },
 'get: path (scalar) ' => sub{ my $u = scalar(uri($url)->path) },
 'set: path (scalar) ' => sub{ uri($url)->path('/foo/bar') },
 'get: path (list)   ' => sub{ my @u = uri($url)->path },
 'set: path (list)   ' => sub{ uri($url)->path(['foo', 'bar']) },
 'get: param (scalar)' => sub{ my $u = uri($url)->param('slack') },
 'get: param (list)  ' => sub{ my @u = uri($url)->param('baz') },
 'set: param (scalar)' => sub{ my $u = uri($url)->param('foo', 'bar') },
 'set: param (list)  ' => sub{ my @u = uri($url)->param('foo', ['bar', 'baz']) },
 'query_keys         ' => sub{ my @u = uri($url)->query_keys },
 'query_hash         ' => sub{ my $u = uri($url)->query_hash },
 'stringification    ' => sub{ my $u = uri($url)->to_string },
 'uri_split          ' => sub{ my @u = uri($url)->to_string },
};
