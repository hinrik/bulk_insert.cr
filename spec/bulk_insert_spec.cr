require "./spec_helper"
require "db"
require "sqlite3"

describe BulkInsert do
  it "inserts the rows" do
    db = DB.open "sqlite3::memory:";
    db.exec "CREATE TABLE test (foo string, bar integer)"

    sql = "INSERT INTO test (foo, bar) VALUES"
    bulk = BulkInsert.new(2, sql, max_args: 999)

    row = ["quux", 1]
    result = bulk.exec(db, row)
    result.should be_a(DB::ExecResult)
    result.rows_affected.should eq(1)

    db.transaction do |tx|
      rows = (1..1000).map { ["quux", 1] }
      rows << ["sfdsf", 9]
      processed, affected = 0, 0
      bulk.exec_many(tx.connection, rows) do |nr_rows, result|
        processed += nr_rows
        result.should be_a(DB::ExecResult)
        affected += result.rows_affected
      end
      processed.should eq(rows.size)
      affected.should eq(rows.size)
    end

    total = db.scalar "SELECT COUNT(*) FROM test"
    total.should eq(1002)
  end
end
