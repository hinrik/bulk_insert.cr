# bulk\_insert

Helper class to perform batched `INSERT`s on a SQL database.

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
    github: hinrik/bulk_insert.cr
```

## Usage

```crystal
require "db"
require "sqlite3"
require "bulk_insert"

db = DB.open "sqlite3::memory:";
db.exec "CREATE TABLE mytable (name string, count integer)"

sql_prefix = "INSERT INTO mytable (name, count) VALUES"
bulk = BulkInsert.new(2, sql_prefix)

# fast bulk importing
data = [["foo", 5], ["bar", 3], ["baz", 9]]
db.transaction do |tx|
  bulk.exec_many(tx.connection, data) do |nr_rows, result|
    puts "Processed #{nr_rows} rows"
  end

  # blockless form
  bulk.exec_many(tx.connection, data)
end

# also supports single-row insert
result = bulk.exec db, ["bla", 123]
```

## How it works

Internally, each object prepares `floor(log2(n))` statements where `n`
is the greatest number <= `max_args` (which is 999 by default)
divisible by the number of columns. This means that for a 2-column
`INSERT`, 9 statements are prepared:

| arguments | rows |
| --------- | -----|
|       998 |  499 |
|       498 |  249 |
|       248 |  124 |
|       ... |  ... |
|         6 |    3 |
|         2 |    1 |

They are then tried in order, executing your batched insert using the
fewest statements possible.

## Contributing

1. Fork it (https://github.com/hinrik/bulk_insert/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Hinrik Örn Sigurðsson](https://github.com/hinrik) Hinrik Örn Sigurðsson - creator, maintainer
