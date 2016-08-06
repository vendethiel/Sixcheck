use lib 'lib';
use Test;
use Sixcheck;

my Sixcheck $checker .= new;

plan 13;

{
  ok $checker.instantiate(Int) ~~ *..*, 'Int generates an int';
}

{
  subset SmallInt of Int where 10..50;
  $checker.register-type(SmallInt, { (10..50).pick });

  $checker.check(SmallInt, * >= 10, :name<minimum value>);
  $checker.check(SmallInt, * <= 50, :name<maximum value>);
}

{
  sub id(Int $n) { $n };
  $checker.check-sub(&id, { $^n == $^n },
    :name<can accept one argument (id returns its argument)>);
}

{
  sub capitalize(Str :$text) { $text.uc }
  $checker.check-sub(&capitalize, -> $x, :$text { $x.lc eq $text.lc },
    :name<will also fill named parameters>);
} 

{
  sub id(Int $n) { $n };
  $checker.check-sub(&id, { $^n == $^n },
    :name<can accept one argument (id returns its argument)>);
  $checker.check-sub(&id, * == *[0],
    :name<can accept two arguments (id returns its argument 0)>);
}

{
  sub add(Int $x, Int $y) { $x + $y };
  $checker.check-sub(&add, { $^x == $^y[0] + $^y[1] },
    :name<can use all the generated arguments>);
}

#sub splat-add(Int *@vals) {
#  @vals[1];
#}
#$checker.check-sub(&splat-add, * == -> $, $v, *@ { $v },
#  :name<it fills in splats>);

{
  multi sub multiple-candidates(Int) { 1 }
  multi sub multiple-candidates(Str) { "2" }

  $checker.check-sub(&multiple-candidates, * == 1 | 2,
    :name<return value>);
   # TODO make sure it fails with either == 1 or == 2
}

{
  my $tested;
  sub fails-on-zero(Int $n) { $tested = True unless $n; }
  $checker.check-sub(&fails-on-zero,
    :name<it checks special cases>);
  ok($tested, "The sub was called with a special case");
}

{
  #sub with-sig(:(Int, Int, Str --> Str) &c) { c(3, 4, "hey") }
  #$checker.check-sub(&with-sig, * ~~ Str,
  #  :name<generates subroutines based on signature>);
}

dies-ok {
  sub with-capture(|c) { 0 }
  $checker.check-sub(&with-capture, * == 0);
}, "Can't generate capture arguments";
