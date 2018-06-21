use utf8;
use ExtUtils::testlib;
use Test2::V0;
use URI::Fast qw(uri);

subtest 'param' => sub{
  foreach my $sep (qw(& ;)) {
    subtest "separator '$sep'" => sub {
      my $uri = uri "http://www.test.com?foo=bar${sep}foo=baz${sep}fnord=slack";
      is [$uri->param('foo')], array{ item 'bar'; item 'baz'; end; }, 'get (list)';
      is $uri->param('fnord'), 'slack', 'get (scalar): single value as scalar';
      ok dies{ my $foo = $uri->param('foo'); }, 'get (scalar): dies when encountering multiple values';

      subtest 'unset' => sub {
        is $uri->param('foo', undef, $sep), U, 'set';
        is $uri->param('foo'), U, 'get';
        is $uri->query, 'fnord=slack', 'updated: query';
      };

      subtest 'set: string' => sub {
        is $uri->param('foo', 'bar', $sep), 'bar', 'set (scalar, single value)';
        is $uri->param('foo'), 'bar', 'get';
        is $uri->query, "fnord=slack${sep}foo=bar", 'updated: query';
      };

      subtest 'set: array ref' => sub {
        is [$uri->param('foo', [qw(bar baz)], $sep)], [qw(bar baz)], 'set';
        is [$uri->param('foo')], [qw(bar baz)], 'get';
        is $uri->query, "fnord=slack${sep}foo=bar${sep}foo=baz", 'updated: query';
        is [$uri->param('qux', 'corge', $sep)], [qw(corge)], 'set qux';
        is [$uri->param('qux')], [qw(corge)], 'get qux';
        is $uri->query, "fnord=slack${sep}foo=bar${sep}foo=baz${sep}qux=corge", 'updated: query';
      };

      subtest 'edge cases' => sub {
        subtest 'empty parameter' => sub {
          my $uri = uri 'http://www.test.com?foo=';
          is $uri->param('foo'), '', 'expected param value';
        };

        subtest 'empty parameter w/ previous parameter parameter' => sub {
          my $uri = uri 'http://www.test.com?bar=baz&foo=';
          is $uri->param('foo'), '', 'expected param value';
        };

        subtest 'empty parameter w/ following parameter' => sub {
          my $uri = uri 'http://www.test.com?foo=&bar=baz';
          is $uri->param('foo'), '', 'expected param value';
        };

        subtest 'unset only parameter' => sub {
          my $uri = uri 'http://www.test.com?foo=bar';
          $uri->param('foo', undef, $sep);
          is $uri->query, '', 'expected query value';
        };

        subtest 'unset final parameter' => sub {
          my $uri = uri "http://www.test.com?bar=bat${sep}foo=bar";
          $uri->param('foo', undef, $sep);
          is $uri->query, 'bar=bat', 'expected query value';
        };

        subtest 'unset initial parameter' => sub {
          my $uri = uri "http://www.test.com?bar=bat${sep}foo=bar";
          $uri->param('bar', undef, $sep);
          is $uri->query, 'foo=bar', 'expected query value';
        };

        subtest 'update initial parameter' => sub {
          my $uri = uri "http://www.test.com?bar=bat${sep}foo=bar";
          $uri->param('bar', 'blah', $sep);
          is $uri->query, "foo=bar${sep}bar=blah", 'expected query value';
        };

        subtest 'update final parameter' => sub {
          my $uri = uri "http://www.test.com?bar=bat${sep}foo=bar";
          $uri->param('foo', 'blah', $sep);
          is $uri->query, "bar=bat${sep}foo=blah", 'expected query value';
        };
      };
    };
  }
};

subtest 'add_param' => sub{
  my $uri = uri 'http://www.test.com';
  is $uri->param('foo', 'bar'), 'bar', 'param';
  is [$uri->add_param('foo', 'baz')], ['bar', 'baz'], 'add_param';
  is [$uri->param('foo')], ['bar', 'baz'], 'add_param';
};

done_testing;
