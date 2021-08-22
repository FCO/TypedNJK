use TypedNJK::Grammar;
unit class TypedNJK:ver<0.0.1>:auth<cpan:FCO>;

has TypedNJK::Grammar $.grammar .= new;

method parse(Str $code) {
    $!grammar.parse: $code
}

=begin pod

=head1 NAME

TypedNJK - WiP NJK with types

=head1 SYNOPSIS

=begin code :lang<raku>

use TypedNJK;

=end code

=head1 DESCRIPTION

TypedNJK is ...

=head1 AUTHOR

Fernando Correa de Oliveira <fernandocorrea@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Fernando Correa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
