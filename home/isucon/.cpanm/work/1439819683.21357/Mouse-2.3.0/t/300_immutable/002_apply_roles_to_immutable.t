#!/usr/bin/perl
# This is automatically generated by author/import-moose-test.pl.
# DO NOT EDIT THIS FILE. ANY CHANGES WILL BE LOST!!!
use t::lib::MooseCompat;

use strict;
use warnings;

use Test::More;
use Test::Exception;


{
    package My::Role;
    use Mouse::Role;

    around 'baz' => sub {
        my $next = shift;
        'My::Role::baz(' . $next->(@_) . ')';
    };
}

{
    package Foo;
    use Mouse;

    sub baz { 'Foo::baz' }

    __PACKAGE__->meta->make_immutable(debug => 0);
}

my $foo = Foo->new;
isa_ok($foo, 'Foo');

is($foo->baz, 'Foo::baz', '... got the right value');

lives_ok {
    My::Role->meta->apply($foo)
} '... successfully applied the role to immutable instance';

is($foo->baz, 'My::Role::baz(Foo::baz)', '... got the right value');

done_testing;
