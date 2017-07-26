use Modern::Perl;
use Test::More;
use IO::All;

my $module;
BEGIN {
$module = 'Bioinfo';
use_ok($module);
}
my @attrs = qw();
my @methods = qw();
can_ok($module, $_) for @attrs;
can_ok($module, $_) for @methods;

done_testing
