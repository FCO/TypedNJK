#use Grammar::Tracer;
use TypedNJK::Grammar::Set;
use TypedNJK::Grammar::Macro;
use TypedNJK::Grammar::Type;

unit grammar TypedNJK::Grammar;
also does TypedNJK::Grammar::Set;
also does TypedNJK::Grammar::Macro;

my \any    = string-to-type "any";
my \number = string-to-type "number";
my \string = string-to-type "string";

my @stack := [ %(), ];

sub string-to-type(Str() $str) {
    do with $str ~~ /^ <TypedNJK::Grammar::type> $/ {
        die "'$str' is not a type" unless .<TypedNJK::Grammar::type>;
        do for .<TypedNJK::Grammar::type><type-name><> {
            .<sym>.Str => .<type>.defined ?? string-to-type(.<type>) !! Pair
        }
    } else {
        die "Error parsing type '\o033[31m$str\o033[m'"
    }
}

method string-to-type(Str() $str) {
    CATCH {
        default {
            self.error: .message
        }
    }
    string-to-type $str
}

rule type { <type-name>+ % "|" }
proto rule type-name { * }
rule type-name:sym<tarray>  { $<sym>="array"  "[" ~ "]" <type> }
rule type-name:sym<tobject> { $<sym>="object" "[" ~ "]" <type> }
rule type-name:sym<enum>    { <sym> "(" ~ ")" \w+ %% "," }
rule type-name:sym<any>     { <sym> }
rule type-name:sym<number>  { <sym> }
rule type-name:sym<string>  { <sym> }
rule type-name:sym<array>   { <sym> }
rule type-name:sym<object>  { <sym> }

multi method test-type(@wanted, @given) {
    so self.test-type: @wanted.any, @given.any
}
multi method test-type($wanted, @given) {
    so self.test-type: $wanted, @given.any
}
multi method test-type(Pair:U, @) { True }
multi method test-type(@, Pair:U) { False }
multi method test-type(Pair:U, Pair:U) { True }
multi method test-type(Pair:D $ where *.key eq "any", Pair:_) { True }
multi method test-type(Pair:_ $wanted, Pair:D $given) {
    return False unless $wanted.key eq $given.key;
    self.test-type: $wanted.value, $given.value
}

method type-to-string(+@type) {
    @type.map({ "{ .key }{ "[{ self.type-to-string: .<> }]" with .value }" }).join: "|"
}

method test-wanted-type($given) {
    unless @*WANT-TYPE { self.error: "Receiving unwanted type '\o033[31m{ self.type-to-string: $given.<> }\o033[m'" }
    self.error: "Wants type '\o033[32m{ self.type-to-string: @*WANT-TYPE }\o033[m' but received '\o033[31m{ self.type-to-string: $given<> }\o033[m'"
        unless self.test-type: @*WANT-TYPE, $given;
}

multi method stack(@val = [%(),]) { @stack = @val; self }
multi method stack                { @stack }

method new-block  { my \b = %(); @stack.push: b; b }
method drop-block { @stack.shift     }

method add-var(Str() $name, Str $type = "any") {
    self.new-block unless @stack;
    self.error: "Variable '\o033[31m$name\o033[m' already defined" if @stack.tail{$name}:exists;
    @stack.tail{$name} = self.string-to-type: $type;
}

method all-vars( --> Hash() ) { @stack.map: |*.self }

method error($msg) is hidden-from-backtrace {
    my $parsed-so-far = self.target.substr(0, self.pos);
    my $break = self.pos + 15;
    with self.target.index("\n", self.pos) {
        $break min= $_ - self.pos
    }
    my $not-parsed = self.target.substr: self.pos, $break;
    my @lines = $parsed-so-far.lines;

    my ($header, $line, $message) = do if @lines {
        "\n\o033[31m===\o033[mSORRY!\o033[31m===\o033[m Error compiling.",
        "Compiling ERROR on line @lines.elems():",
        "$msg: \o033[32m@lines[*-1].trim-leading()\o033[33m⏏\o033[31m$not-parsed\o033[m"
    } else {
        "\n\o033[31m===\o033[mSORRY!\o033[31m===\o033[m Error compiling.",
        "\o033[33mError parsing.\o033[m",
        $msg
    }

    if $*THROW-INSTEAD-OF-EXIT {
        die join "\n", [ $header, $line, $message ];
    }

    note $header;
    note $line;
    note $message;
    exit 1;
}

rule TOP { <tmpl>* }

proto rule tmpl { * }
rule tmpl:sym<value> { <value>+ }
rule tmpl:sym<text>  { <text>+ }

rule value {
    '{{' ~ '}}' [
        :my @*WANT-TYPE := any;
        <code>
    ]
}

token number {
    ["-"|"+"]? [ \d+ | \d* "." \d+ ]
    { self.test-wanted-type: number }
}

token variable {
    <var-name> {}
    :my %vars := self.all-vars;
    :my $type := self.all-vars{ $<var-name>.Str };
    # TODO: <?{ $type }>
    # TODO: Remove error
    { $type // $.error: "Variable '\o033[33m$<var-name>\o033[m' not declared" }
    { self.test-wanted-type: $type }
}

rule infix1 {
    :my @*WANT-TYPE = any;
    $<left>=[ <.number> || <.variable> ] <op1>
    { self.test-type: self.all-vars{ .Str } with $<variable> }
    { @*WANT-TYPE := number }
    <right=.code>
    { self.test-wanted-type: number }
}

rule infix2 {
    :my @*WANT-TYPE = any;
    $<left>=[ <.number> || <.variable> || <.infix1> ] <op2>
    { self.test-type: self.all-vars{ .Str } with $<variable> }
    { @*WANT-TYPE := number }
    <right=.code>
    { self.test-wanted-type: number }
}

rule infix3 {
    :my @*WANT-TYPE = any;
    $<left>=[ <.number> || <.variable> || <.infix2> ] <op3>
    { self.test-type: self.all-vars{ .Str } with $<variable> }
    { @*WANT-TYPE := number }
    <right=.code>
    { self.test-wanted-type: number }
}

proto rule code { * }
token code:sym<undef>    { undefined }
token code:sym<null>     { null }
token code:sym<infix1>   { <infix1> }
token code:sym<infix2>   { <infix2> }
token code:sym<number>   { <number> }
token code:sym<sstring>  {
    \' ~ \' [<-[']> | <?after \\> \']+
    { self.test-wanted-type: string }
}
token code:sym<dstring> {
    \" ~ \" [<-["]> | <?after \\> \"]+
    { self.test-wanted-type: string }
}
token code:sym<array> {
    '[' ~ ']' [
        { self.test-wanted-type: self.string-to-type("array").<> }
        :my @*WANT-TYPE := @*WANT-TYPE.grep(*.key eq "array").map: |*.value.<>;
        <code>* % ","
    ]
}
token code:sym<var>     { <variable> }

proto token op3 {*}
token op1:sym<**> { <.sym> }

proto token op2 {*}
token op2:sym<*> { <.sym> }
token op2:sym</> { <.sym> }

proto token op1 {*}
token op2:sym<+> { <.sym> }
token op2:sym<-> { <.sym> }

token var-name { <+[\w]-[\d-]> \w* }

rule text { <-[{]>+ }

rule block-tag(Regex $reg) {
    '{%' ~ '%}' $reg
}

rule var-decl {
    <var-name>
    [":" <type> ]? {}
    :my Str() $type = $<type> // 'any';
    [
        "="
        # TODO: should the type (when not defined) be defined by the code's type
        :my @*WANT-TYPE = self.string-to-type: $type;
        <code>
    ]?
    { self.add-var: $<var-name>, |($_ with $type) }
}
