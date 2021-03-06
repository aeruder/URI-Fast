use utf8;
use ExtUtils::testlib;
use Test2::V0;
use URI::Encode::XS qw(uri_encode_utf8 uri_decode_utf8);
use URI::Fast qw(uri);

my $url       = 'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff';
my $reserved  = q{! * ' ( ) ; : @ & = + $ , / ? # [ ] %};
my $utf8      = "Ῥόδος¢€";
my $malformed = 'p%EErl%E1%BF%AC+%CF%82';

subtest 'basics' => sub{
  is URI::Fast::encode('asdf'), 'asdf', 'non-reserved';
  is URI::Fast::encode('&', '&'), '&', 'allowed';

  is URI::Fast::encode('asdf'), 'asdf', 'non-reserved';

  is(URI::Fast::encode($_), sprintf('%%%02X', ord($_)), "reserved char $_")
    foreach split ' ', $reserved;

  is URI::Fast::decode(URI::Fast::encode($reserved)), $reserved, 'decode';

  is URI::Fast::encode(" &", "&"), "%20&", "encode: allowed chars";
};

subtest 'negative path' => sub {
  is URI::Fast::decode("foo %"), "foo %", "terminal %";
  is URI::Fast::decode("% foo"), "% foo", "leading %";
};

subtest 'utf8' => sub{
  my $u = "Ῥόδος";
  my $a = '%E1%BF%AC%CF%8C%CE%B4%CE%BF%CF%82';

  is URI::Fast::encode('$'), uri_encode_utf8('$'), '1 byte';
  is URI::Fast::encode('¢'), uri_encode_utf8('¢'), 'encode_utf8: 2 bytes';
  is URI::Fast::encode('€'), uri_encode_utf8('€'), 'encode_utf8: 3 bytes';
  is URI::Fast::encode('􏿿'), uri_encode_utf8('􏿿'), 'encode_utf8: 4 bytes';
  is URI::Fast::encode($u), $a, 'encode_utf8: string';

  is URI::Fast::encode($u), $a, 'encode';
  ok !utf8::is_utf8(URI::Fast::encode($u)), 'encode: result is not flagged utf8';

  is URI::Fast::decode($a), $u, 'decode';

  ok my $uri = uri($url), 'ctor';

  is $uri->auth("$u:$u\@www.$u.com:1234"), "$a:$a\@www.$a.com:1234", 'auth';

  is $uri->usr, $u, 'usr';
  is $uri->pwd, $u, 'pwd';
  is $uri->host, "www.$u.com", 'host';

  is $uri->path("/$u/$u"), "/$u/$u", "path";
  is $uri->path([$u, $a]), "/$u/$a", "path";

  is $uri->query("x=$a"), "x=$a", "query";
  is $uri->param('x'), $u, 'param', $uri->get_query;
  is $uri->query({x => $u}), "x=$a", "query", $uri->get_query;
  is $uri->param('x'), $u, 'param', $uri->get_query;

  ok my $mal = URI::Fast::decode($malformed), 'decode: malformed';
  ok !utf8::is_utf8($mal), 'decode: utf8 flag not set when malformed';
};

done_testing;
