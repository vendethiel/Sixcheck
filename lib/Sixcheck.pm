class Sixcheck;

has $!create = :{
  DEFAULT => *.new,
  (Int) => { round rand * 1000 }
}

method register-type(Mu:U \type, Callable $code) {
  die "Type already registered: $(type.perl)" if $!create{type}:exists;
  $!create{type} = $code;
}

method instantiate(Mu:U \type) {
  if $!create{type}:exists {
    $!create{type}();
  } else {
    $!create<DEFAULT>(type);
  }
}

method check(Mu:U \type, Callable $code, Int :$iterations = 100) {
  use Test;
  subtest {
    plan $iterations;
    for ^$iterations {
      my $value = $.instantiate(type);
      ok $code($value), "Invariant does not hold for type $(type.perl) and value $($value.Str.substr(0, 50))";
    }
  }
}
