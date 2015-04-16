class Sixcheck;

has Int $.iterations = 100;

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

method check(Mu:U \type, Callable $code, :$name) {
  use Test;
  for ^$.iterations {
    my $value = $.instantiate(type);
    # todo use live_ok here? (for PRE/POST invariants)
    if !$code($value) {
      flunk "Invariant $name does not hold for type $(type.perl) and value $(self!format($value)) from $(callframe.file):$(callframe.line)";
      return;
    }
  }
  pass "Invariant $name holded for type $(type.perl) for every value tested.";
}

#subset MultiSub of Sub where *.candidates.elems > 1;
#multi method check-sub(MultiSub $f, Callable $code) {
#  $.check-sub($_, $code) for $f.candidates;
#}

multi method check-sub(Callable $f, Callable $code, :$name = '') {
  use Test;
  my $sub-name = $f.name || "<anon>";
  for ^$.iterations {
    my @capture = self!generate-for-sig($f.signature);
    my $value = $f(|@capture);
    if !$code($value) {
      flunk "Invariant $name does not hold for sub $sub-name and value $(self!format($value))";
      return;
    }
  }
  pass "Invariant $name holded for sub $name for every value tested.";
}

method !generate-for-sig(Signature $c) {
  gather for $c.params {
    # TODO do something with invocant?
    when .capture {
      die "Capture parameter NYI";
    }
    when .named {
      # pick one of the .named-names... Doesn't matter.
      take .named-names.pick => $.instantiate(.type);
    }
    when .positional && .optional {
      take $.instantiate(.type) if Bool.pick;
    }
    when .positional {
      take $.instantiate(.type);
    }
    when .slurpy {
      take $.instantiate(.type) xx (^25).pick; # arbitrary number
    }
    default {
      die "Unable to generate anything for parameter $(.perl)";
    }
  }
}

method !format($_) { $_.Str.substr(0, 50) }
