use strict;
use warnings;

use Test::More;
use Class::Load 'is_class_loaded';
use lib "t/lib";

BEGIN {
  if ($^O =~ m/^MSWin/) {
    plan skip_all => 'Skipping this test on Windows until someone with Windows has time to fix it';
  }

  use_ok("Catalyst::Utils");
}

{
    package This::Module::Is::Not::In::Inc::But::Does::Exist;
    sub moose {};
}

my $warnings = 0;
$SIG{__WARN__} = sub {
    return if $_[0] =~ /Subroutine (?:un|re|)initialize redefined at .*C3\.pm/;
    $warnings++;
};

ok( !is_class_loaded("TestApp::View::Dump"), "component not yet loaded" );

Catalyst::Utils::ensure_class_loaded("TestApp::View::Dump");

ok( is_class_loaded("TestApp::View::Dump"), "loaded ok" );
is( $warnings, 0, "no warnings emitted" );

$warnings = 0;

Catalyst::Utils::ensure_class_loaded("TestApp::View::Dump");
is( $warnings, 0, "calling again doesn't reaload" );

ok( !is_class_loaded("TestApp::View::Dump::Request"), "component not yet loaded" );

Catalyst::Utils::ensure_class_loaded("TestApp::View::Dump::Request");
ok( is_class_loaded("TestApp::View::Dump::Request"), "loaded ok" );

is( $warnings, 0, "calling again doesn't reaload" );

undef $@;
eval { Catalyst::Utils::ensure_class_loaded("This::Module::Is::Probably::Not::There") };
ok( $@, "doesn't defatalize" );
like( $@, qr/There\.pm.*\@INC/, "error looks right" );

undef $@;
eval { Catalyst::Utils::ensure_class_loaded("__PACKAGE__") };
ok( $@, "doesn't defatalize" );
like( $@, qr/__PACKAGE__\.pm.*\@INC/, "errors sanely on __PACKAGE__.pm" );

$@ = "foo";
Catalyst::Utils::ensure_class_loaded("TestApp::View::Dump::Response");
is( $@, "foo", '$@ is untouched' );

undef $@;
eval { Catalyst::Utils::ensure_class_loaded("This::Module::Is::Not::In::Inc::But::Does::Exist") };
ok( !$@, "no error when loading non existent .pm that *does* have a symbol table entry" ); 

undef $@;
eval { Catalyst::Utils::ensure_class_loaded('Silly::File::.#Name') };
like($@, qr/Malformed class Name/, 'errored when attempting to load a file beginning with a .');

undef $@;
eval { Catalyst::Utils::ensure_class_loaded('Silly::File::Name.pm') };
like($@, qr/Malformed class Name/, 'errored sanely when given a classname ending in .pm');

undef $@;
$warnings = 0;
Catalyst::Utils::ensure_class_loaded("NullPackage");
is( $warnings, 1, 'Loading a package which defines no symbols warns');
is( $@, undef, '$@ still undef' );

done_testing;
