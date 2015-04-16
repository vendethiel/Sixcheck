use lib 'lib';
use Test;
use Sixcheck;

my Sixcheck $checker .= new;

plan 5;

ok $checker.instantiate(Int) ~~ *..*, 'Int generates an int';

subset SmallInt of Int where 10..50;
$checker.register-type(SmallInt, { (10..50).pick });

$checker.check(SmallInt, * >= 10, :name<minimum value>);
#$checker.check(SmallInt, * > 10); uncomment to fail! (don't forget to fix plan;)
$checker.check(SmallInt, * <= 50, :name<maximum value>);

multi sub f(Int) { 1 }
multi sub f(Str) { "2" }

# TODO once rakudo's bug with MultiSub is fix, remove the .candidates[0]
$checker.check-sub(&f.candidates[0], * == 1 | 2, :name<return value>);

dies_ok {
  sub with-capture(|c) { 0 }
  $checker.check-sub(&with-capture, * == 0);
}, "Can't generate capture arguments";
