use Test;
use TypedNJK::Grammar;

my &t = *.Str.trans: " " => "␠", "\t" => "␉", "\n" => "␤";

proto find-key($, $ --> Bool) is export is test-assertion {*}
multi find-key(@value, $key --> Bool) {
    so @value.any.&find-key: $key
}
multi find-key(%value, $key --> Bool) {
    return True with %value{ $key };
    so %value.values.any.&find-key: $key
}
multi find-key($, $ --> False) {}

multi from-path(\data,       [])                     { data }
multi from-path(@data,       [Int() $index, *@rest]) { from-path @data[ $index ], @rest }
multi from-path(Match $data, [Str() $key,  *@rest])  { from-path $data{ $key   }, @rest }

sub test-parsed(
    Str $str,
    &block?,
    :$msg = "Testing:",
    :@also,
    :@path = ([], |@also),
    :@stack,
) is export is test-assertion is hidden-from-backtrace {
    with TypedNJK::Grammar.new.stack(@stack).parse: $str {
        .gist.&diag if %*ENV<TEST_DIAG>;
        .&ok: "$msg matched";
        my @p = @path.map: { $_ ~~ Pair ?? (.key.list => .value) !! (.list => Nil) }
        for @p -> (:@key, :$value) {
            if $value.defined and $value ~~ Int {
                is .&from-path(@key).elems, $value, "$msg count $value <{ @key }>: { t $str }";
            } else {
                is .&from-path(@key).Str, $value // $str, "$msg <{ @key }> { t $value // $str }";
            }
        }
        block($_) if &block
    }
    else {
        flunk "Could not parse: { t $str }";
    }
}

sub test-key($_, Str $key, Bool :$has = True) is export is test-assertion {
    if $has {
        ok .&find-key($key), "It has key $key"
    } else {
        nok .&find-key($key), "It hasn't key $key"
    }
}
