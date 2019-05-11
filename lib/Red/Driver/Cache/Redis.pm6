use v6.d;
use Red::Driver::CacheWithStrKey;
use JSON::Fast;
use Redis;
unit class Red::Driver::Cache::Redis:ver<0.0.1> does Red::Driver::CacheWithStrKey;

has Str   $.host   = "127.0.0.1";
has UInt  $.port   = 6379;
has Redis $.redis .= new: "{ $!host }:{ $!port }";
has UInt  $.ttl    = 10;

multi method get-from-cache(Str $key)  {
    with $!redis.get($key) {
        my Str $str = .decode;
        return from-json $str
    }
}

multi method set-on-cache(Str $key, @data) {
    $!redis.setex: $key, $!ttl, to-json @data
}

=begin pod

=head1 NAME

Red::Driver::Cache::Redis - blah blah blah

=head1 SYNOPSIS

=begin code :lang<perl6>

use Red;
use Red::Driver::Cache;

model Bla {
    has UInt $.id  is serial;
    has Str  $.bla is column;
}

my $*RED-DB = cache (Redis => :10ttl), (SQLite => \( :database<./bla.db> ));

Bla.^create-table: :if-not-exists;

Bla.^create(:bla("blablabla " ~ ++$)) for ^20;

my $*RED-CACHE-DEBUG = True;
say Bla.^all.grep: *.bla.starts-with: "a"; # Stores the result on Redis
say Bla.^all.grep: *.bla.starts-with: "a"; # Uses the data stored on Redis

=end code

=head1 DESCRIPTION

Red::Driver::Cache::Redis is a Red plugin to cache queries on Redis

=head1 AUTHOR

Fernando Correa de Oliveira <fernandocorrea@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Fernando Correa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
