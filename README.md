# bulk\_insert

Helper class to perform batched `INSERTS` on a SQL database.

When inserting large amounts of rows at a time, including values for
multiple rows in a single `INSERT` is faster than executing an `INSERT`
for every row.

This class takes care of that for you, including preparing the necessary
statements and executing them for any number of rows.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  bulk_insert:
    github: hinrik/bulk_insert
```

## Usage

```crystal
require "sqlite3"
require "bulk_insert"

db = DB.open "sqlite3::memory:";
db.exec "CREATE TABLE mytable (name string, count integer)"
bulk = BulkInsert.new(db, 2, sql)

data = [["foo", 5], ["bar", 3], ["baz", 9]]
sql = "INSERT INTO mytable (name, count) VALUES"
db.exec "BEGIN"
bulk.exec_for_rows data
db.exec "COMMIT"
```

## Contributing

1. Fork it (https://github.com/hinrik/bulk\_insert/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Hinrik Örn Sigurðsson](https://github.com/hinrik) Hinrik Örn Sigurðsson - creator, maintainer
