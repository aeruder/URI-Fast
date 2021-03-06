use utf8;
use ExtUtils::testlib;
use Test2::V0;
use URI::Fast qw(uri);

my @uris = (
  '/foo/bar/baz',
  'http://www.test.com',
  'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff',
  'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
);

ok(uri($_), 'uri') foreach @uris;

is uri(undef), '', 'undef';
is uri(''), '', 'empty string';

is uri('/foo')->scheme, '', 'missing scheme';
is uri('http://'), 'http://', 'non-file scheme w/o host';
is uri('http://test'), 'http://test', 'auth w/ invalid host';

is uri('http://usr:pwd')->usr, '', 'no usr w/o @';
is uri('http://usr:pwd')->pwd, '', 'no pwd w/o @';
is uri('http://usr:pwd')->host, 'usr', 'host w/ invalid port';
is uri('http://usr:pwd')->port, '', 'invalid port number ignored';

is uri('#')->frag, '', 'fragment empty but starts with #';

subtest 'param' => sub{
  is uri('?')->param('foo'), undef, 'empty query';
  is uri('?foo')->param('foo'), undef, 'query key w/o =value';
  is uri('?foo=')->param('foo'), '', 'query key w/o value';
  is uri('?=bar')->param('foo'), undef, 'query =value w/o key && request key ne value';
  is uri('?=bar')->param('bar'), undef, 'query =value w/o key && request key eq value';
  is uri('?=')->param('foo'), undef, 'query w/ = but w/o key or value';
  is uri('???')->param('??'), undef, 'multiple question marks';
};

subtest 'query_hash' => sub{
  is uri('?')->query_hash, hash{ end }, 'empty query';
  is uri('?foo')->query_hash, hash{ field 'foo' => array{ end }; end }, 'query key w/o =value';
  is uri('?foo=')->query_hash, hash{ field 'foo' => array{ end }; end }, 'query key w/o value';
  is uri('?=bar')->query_hash, hash{ end }, 'query =value w/o key';
  is uri('?=')->query_hash, hash{ end }, 'query w/ = but w/o key or value';
  is uri('???')->query_hash, hash{ field '??' => array{ end }; end }, 'multiple question marks';
};

subtest 'split_path' => sub{
  is uri('//foo/baz.png')->split_path, array{
    item '';
    item 'foo';
    item 'baz.png';
    end;
  }, 'double leading slashes';

  is uri('/foo/bar/')->split_path, array{
    item 'foo';
    item 'bar';
    end;
  }, 'trailing slash';

  is uri('/foo/bar//')->split_path, array{
    item 'foo';
    item 'bar';
    item '';
    end;
  }, 'double trailing slashes';

  is uri('/foo//bar')->split_path, array{
    item 'foo';
    item '';
    item 'bar';
    end;
  }, 'double internal slashes';
};

subtest 'overruns' => sub{
   # scheme: 16
   # auth:   267
   # path:   256
   # query:  1024
   # frag:   32
   # usr:    64
   # pwd:    64
   # host:   128
   # port:   8
   ok uri(sprintf('%s://www.test.com', 'x' x 17)), 'scheme';
   ok uri(sprintf('http://%s', 'x' x 265)), 'auth';
   ok uri(sprintf('http://%s:foo@www.test.com', 'x' x 65)), 'usr';
   ok uri(sprintf('http://someone:%s@www.test.com', 'x' x 65)), 'pwd';
   ok uri(sprintf('http://%s', 'x' x 129)), 'host';
   ok uri('http://www.test.com:1234567890'), 'port';
   ok uri(sprintf('http://www.test.com/%s', 'x' x 257)), 'path';
   ok uri(sprintf('http://www.test.com/foo/?%s', 'x' x 1025)), 'query';
   ok uri(sprintf('http://www.test.com/foo#%s', 'x' x 33)), 'frag';
};

done_testing;
