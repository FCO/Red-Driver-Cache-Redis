use v6.d;
use Red::Database;
use Red::Driver;
use Red::AST;
use Red::AST::Select;
use Red::AST::Infix;
use Red::AST::Value;
use Red::AST::LastInsertedRow;
use Red::Statement;
use JSON::Fast;
use Redis;
unit class Red::Driver::Cache::Redis:ver<0.0.1> does Red::Driver;

has Str          $.driver-name is required;
has Capture      $.driver-capture = \();
has Red::Driver  $.driver         = database $!driver-name, |$!driver-capture;
has Str          $.redis-host     = "127.0.0.1";
has UInt         $.redis-port     = 6379;
has Redis        $.redis         .= new: "{ $!redis-host }:{ $!redis-port }";

class X::Red::Driver::Cache::Redis::DoNotCache is Exception {}

multi method default-type-for(Red::Column $a --> Str:D) { $!driver.default-type-for($a)      }
multi method is-valid-table-name(|c)                    { $!driver.is-valid-table-name(|c)   }
multi method type-by-name(|c)                           { $!driver.type-by-name(|c)          }
multi method inflate(|c)                                { $!driver.inflate(|c)               }
multi method deflate(|c)                                { $!driver.deflate(|c)               }
multi method prepare(Str $_)                            { $!driver.prepare($_)               }
multi method translate(Red::AST $ast, $context?)        { $!driver.translate($ast, $context) }

class CachedStatement does Red::Statement {
    has Iterator    $.iterator;

    method stt-exec($stt, *@bind) { }
    method stt-row($stt) { $!iterator.pull-one }
}

class Statement does Red::Statement {
    has Str            $.cache-key is required;
    has Red::Statement $.stt       is required;
    has Redis          $.redis     is required;
    has Iterator       $.iterator;
    # Remove the hardcoded value
    has UInt           $.ttl       = 60;

    method stt-exec($stt, *@bind) {
        my @data;
        $!stt.stt-exec: $!stt, |@bind;
        while my $row = $!stt.row {
            @data.push: $row
        }
        note "Caching on $!cache-key" if $*RED-CACHE-REDIS-DEBUG;
        $!redis.setex: $!cache-key, $!ttl, to-json @data;
        $!iterator = @data.iterator
    }
    method stt-row($stt) { $!iterator.pull-one }
}

multi method prepare(Red::AST::Select $_ ) {
    CATCH {
        default {
            return $!driver.prepare: $_
        }
    }
    my $cache-key = self.translate-key: $_, "select";
    with $!redis.get: $cache-key {
        note "Got from cache: $cache-key" if $*RED-CACHE-REDIS-DEBUG;
        return CachedStatement.new: :driver(self), :iterator((from-json .decode).iterator)
    }
    do for $!driver.prepare: $_ -> $stt {
        Statement.new: :driver(self), :$!redis, :$stt, :$cache-key
    }
}

multi method translate-key(Red::AST::LastInsertedRow $_, $context?)  {
    X::Red::Driver::Cache::Redis::DoNotCache.new.throw
}

multi method translate-key(Red::Column $_, $context?)  {
    (.computation // $_).gist.subst: /\s+/, "_", :g
}

multi method translate-key(Red::Model:U $_, "table-list")  {
    .^table
}

multi method translate-key(Red::Model:U $_, "of")  {
    .^columns>>.column.map({ self.translate-key: $_, "of" }).join: "|"
}

multi method translate-key(Red::AST::Infix $_, $context)  {
    "{ self.translate-key: .left, $context }_{ .op }_{ self.translate-key: .right, $context }"
}

multi method translate-key(Red::AST::Value $_, $context)  {
    .value.Str
}

multi method translate-key(Red::AST::Select $_, $context?)  {
    (
        "CACHED_SELECT",
        self.translate-key(.of, "of"),
        "FROM",
        .tables.grep({ not .?no-table }).unique.map({ self.translate-key: $_, "table-list" }).join("|"),
        (|(
            "WHERE",
            self.translate-key($_, "filter"),
        ) with .filter),
        (|(
            "ORDER_BY",
            .order.map({ self.translate-key: $_, "order" }).join: "|"
        ) if .order),
        |( "LIMIT", .limit if .limit),
        |( "OFFSET", .offset if .offset),
    ).join: ":"
}
=begin pod

=head1 NAME

Red::Driver::Cache::Redis - blah blah blah

=head1 SYNOPSIS

=begin code :lang<perl6>

use Red::Driver::Cache::Redis;

=end code

=head1 DESCRIPTION

Red::Driver::Cache::Redis is ...

=head1 AUTHOR

Fernando Correa de Oliveira <fernandocorrea@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Fernando Correa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
