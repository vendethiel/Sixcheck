use lib 'lib';
use Test;
use Sixcheck;

my Sixcheck $checker .= new;

plan 9;

ok $checker.instantiate(Int) ~~ *..*, 'Int generates an int';

subset SmallInt of Int where 10..50;
$checker.register-type(SmallInt, { (10..50).pick });

$checker.check(SmallInt, * >= 10, :name<minimum value>);
#$checker.check(SmallInt, * > 10); uncomment to fail! (don't forget to fix plan;)
$checker.check(SmallInt, * <= 50, :name<maximum value>);

sub id(Int $n) { $n };
$checker.check-sub(&id, { $^n == $^n }, :name<can accept one argument (id returns its argument)>);
$checker.check-sub(&id, * == *[0], :name<can accept two arguments (id returns its argument 0)>);

sub add(Int $x, Int $y) { $x + $y };
$checker.check-sub(&add, * == *.reduce(*+*),
  :name<can use all the generated arguments>);

sub capitalize(Str :$text) { $text.uc }
$checker.check-sub(&capitalize, { $^x.elems == $:text.elems }, :name<will also fill named parameters>);

multi sub multiple-candidates(Int) { 1 }
multi sub multiple-candidates(Str) { "2" }

# TODO once rakudo's bug with MultiSub is fix, remove the .candidates[0]
$checker.check-sub(&multiple-candidates.candidates[0], * == 1 | 2,
  :name<return value>);

dies_ok {
  sub with-capture(|c) { 0 }
  $checker.check-sub(&with-capture, * == 0);
}, "Can't generate capture arguments";
