[![Build Status](https://travis-ci.org/FCO/Red-Driver-Cache-Redis.svg?branch=master)](https://travis-ci.org/FCO/Red-Driver-Cache-Redis)

NAME
====

Red::Driver::Cache::Redis - blah blah blah

SYNOPSIS
========

```perl6
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
```

DESCRIPTION
===========

Red::Driver::Cache::Redis is a Red plugin to cache queries on Redis

AUTHOR
======

Fernando Correa de Oliveira <fernandocorrea@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Fernando Correa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

