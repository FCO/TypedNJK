use TypedNJK::Grammar::Type;
unit role TypedNJK::Grammar::Macro;

my %macros; # where .values<>.all.value ~~ Type;

rule tmpl:sym<macro-decl> {
    [
        '{%' ~ '%}'
        [
            "macro" <macro-name=var-name>
            "(" ~ ")" [
                :my %b := self.new-block;
                <var-decl>* % ","
            ]
        ]
        { %macros{ $<macro-name>.Str } = $<var-decl>.map({ .<var-name>.Str => %b{ .<var-name>.Str } }).list }
    ] ~ <.block-tag(/"endmacro"/)>
    <TOP>
}

rule tmpl:sym<macro-call> {
    [ '{%' ~ '%}' [ 'call' <call-macro> ] ] ~ <.block-tag(/'endcall'/)> <TOP>
}

rule code:sym<call-macro> {
    <call-macro>
}

rule arg(@args) {
    :my @*WANT-TYPE := @args.shift.value<>;
    <code>
}

token call-macro {
    <name=.var-name> {}
    :my @args := %macros{ $<name>.Str }.clone.Array;
    "(" ~ ")" <arg( @args )> ** { +@args }
}
