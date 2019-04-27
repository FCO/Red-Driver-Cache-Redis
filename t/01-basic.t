use v6.c;
use Test;
use Red;
use Red::Driver::Cache::Redis;

model Bla {
    has UInt $.id is serial;
    has Str  $.bla is column;
}

my $*RED-DB = database "Cache::Redis", :driver-name<SQLite>, :driver-capture(\(:database<./bla.db>));
Bla.^create-table: :if-not-exists;

Bla.^create(:bla("blablabla " ~ ++$)) for ^20;

my $*RED-CACHE-REDIS-DEBUG = True;
say Bla.^all.grep: *.bla.starts-with: "a";
say Bla.^all.map(*.id * 2);
say Bla.^all.sort(*.id).head: 10;
say Bla.^all.sort(*.id).batch(3)[2];

done-testing;
