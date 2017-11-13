require "./spec_helper"
require "sqlite3"

describe BulkInsert do
  it "inserts the rows" do
    db = DB.open "sqlite3::memory:";
    db.exec "CREATE TABLE test (foo string, bar integer)"

    sql = "INSERT INTO test (foo, bar) VALUES"
    bulk = BulkInsert.new(db, 2, sql, max_args: 999)

    row = ["quux", 1]
    result = bulk.exec(row)
    result.should be_a(DB::ExecResult)
    result.rows_affected.should eq(1)

    db.exec "BEGIN"
    rows = (1..1000).map { ["quux", 1] }
    rows << ["sfdsf", 9]
    processed, affected = 0, 0
    bulk.exec_many(rows) do |nr_rows, result|
      processed += nr_rows
      result.should be_a(DB::ExecResult)
      affected += result.rows_affected
    end
    processed.should eq(rows.size)
    affected.should eq(rows.size)
    db.exec "COMMIT"

    total = db.scalar "SELECT COUNT(*) FROM test"
    total.should eq(1002)
  end
end
