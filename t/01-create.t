use lib 'lib';
use Test;
use Sixcheck;

my Sixcheck $checker .= new;

plan 3;

subtest {
  plan 1;
  ok $checker.instantiate(Int) ~~ *..*, 'Int generates an int';
}, "Sanity check";

subset SmallInt of Int where 10..50;
$checker.register-type(SmallInt, { (10..50).pick });

$checker.check(SmallInt, * >= 10);
#$checker.check(SmallInt, * > 10); uncomment to fail! (don't forget to fix plan;)
$checker.check(SmallInt, * <= 50);

multi sub f(Int) { 1 }
multi sub f(Str) { "2" }

$checker.check-sub(&f, * == 1 | "2");

# TODO check return type
