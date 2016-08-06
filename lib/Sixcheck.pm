unit class Sixcheck;

has Int $.iterations is rw = 100;

my @r = flat("a".."z", "A".."Z");

has $!create;

submethod BUILD() {
  $!create = :{
    DEFAULT => *.new,
    (Int) => { (-5000..5000).pick },
    (Str) => { join '', @r.pick xx (^25).pick },
    (Signature) => -> Signature $sig {
      # return a sub accepting anything...
      -> | { self.instantiate($sig.returns) }
    },
  };
}

has $!special-cases = :{
  (Int) => (-1, 0, 1),
  (Str) => ("") # TODO add some unicode weirdness I guess
};

method register-type(Mu:U \type, Callable $check) {
  die "Type already registered: $(type.perl)" if $!create{type}:exists;
  $!create{type} = $check;
}

method instantiate(Mu:U \type) {
  # a special case will be used one in fifth time
  if $!special-cases{type} && !(^5).pick {
    $!special-cases{type}.pick;
  } elsif $!create{type} -> $t {
    if $t.arity == 0 {
      $t() 
    } elsif .arity == 1 {
      $t(type)
    } else {
      die "Invalid arity for type instantiation"
    }
  } else {
    $!create<DEFAULT>(type);
  }
}

method check(Mu:U \type, Callable $check, :$name) {
  use Test;
  for ^$.iterations {
    my $value = $.instantiate(type);
    # todo use live_ok here? (for PRE/POST invariants)
    if not $check($value) {
      flunk "Invariant $name does not hold for type $(type.perl) and value $(self!format($value)) from $(callframe.file):$(callframe.line)";
      return;
    }
  }
  pass "Invariant $name held for type $(type.perl) for every value tested.";
}

#subset MultiSub of Sub where .candidates.elems > 1;
#multi method check-sub(MultiSub $f, Callable $check) {
#  $.check-sub($_, $check) for $f.candidates;
#}

multi method check-sub(Callable $f, :$name!) {
  use Test;
  my $sub-name = $f.name || "<anon>";
  for ^$.iterations {
    my ($named, $pos) = self!generate-for-sig($f.signature);
    $f(|$named, |$pos);
    CATCH {
      default {
        flunk "Check '$name' failed for sub $sub-name called with $(self!format($pos.perl)) and $(self!format($named.perl))";
        return;
      }
    }
  }
  pass "Invariant '$name' held for sub $sub-name for every value tested.";
}

multi method check-sub(Callable $f, Callable $check, :$name!) {
  use Test;
  my $sub-name = $f.name || "<anon>";
  for ^$.iterations {
    my ($named, $pos) = self!generate-for-sig($f.signature);
    my $value = $f(|$named, |$pos);
    if not self!call-check($check, $pos, %$named, $value) {
      flunk "Invariant '$name' does not hold for sub $sub-name called with $(self!format($pos.perl)) and $(self!format($named.perl)) (returned $(self!format($value)))";
      return;
    }
  }
  pass "Invariant '$name' held for sub $sub-name for every value tested.";
}

method !call-check(Callable $check, $pos, %named, $value) {
  given $check.arity {
    when 1 {
      $check($value, |%named);
    }
    when 2 {
      $check($value, $pos, |%named);
    }
    default {
      die "Cannot call check function with arity $_.";
    }
  }
}

method !generate-for-sig(Signature $c) {
  my %named;
  my @pos = gather for $c.params {
    when .capture {
      die "Capture parameter NYI";
    }
    when .named {
      # pick one of the .named_names... Doesn't matter.
      %named{.named_names.pick} = $.instantiate(.type);
    }
    when .positional && .optional {
      take $.instantiate(.type) if Bool.pick;
    }
    when .positional {
      take $.instantiate(.type);
    }
    when .slurpy {
      take $.instantiate(.type) xx (^25).pick;
    }
    default {
      die "Unable to generate anything for parameter $(.perl)";
    }
  }
  $%named, $@pos
}

method !format($_) { $_.Str.substr(0, 50) }
