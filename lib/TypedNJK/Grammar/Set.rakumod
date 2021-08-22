#use Grammar::Tracer;
unit role TypedNJK::Grammar::Set;

rule set-open-block {
    '{%' ~ '%}'
    [
        "set"
        <var-name>
        [":" <type> ]?
    ]
}
rule tmpl:sym<set-block> {
    <set-open-block> ~ <.block-tag(/"endset"/)> <TOP>
    { self.add-var: $<set-open-block><var-name>, |($_ with $<set-open-block><type>) }
}
rule tmpl:sym<set-asign> {
    '{%' ~ '%}'
    [ "set" <var-decl> ]
    <?{ $<var-decl><code> }>
}
