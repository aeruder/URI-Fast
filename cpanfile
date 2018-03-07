requires 'perl', '5.010';

requires 'Carp';
requires 'Exporter';
requires 'Inline::C' => '0.78';

on test => sub {
  requires 'Test2'           => '1.302125';
  requires 'Test2::Suite'    => '0.000100';
  requires 'Test2::V0'       => 0;
  requires 'Test::LeakTrace' => '0.16';
  requires 'Test::Pod'       => 1.41;
  requires 'URI::Split'      => 0;
  requires 'URI::Encode::XS' => '0.11';
};
