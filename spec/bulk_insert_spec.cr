require "./spec_helper"
require "sqlite3"

describe BulkInsert do
  it "inserts the rows" do
    db = DB.open "sqlite3::memory:";
    db.exec "CREATE TABLE test (foo string, bar integer)"

    sql = "INSERT INTO test (foo, bar) VALUES"
    bulk = BulkInsert.new(db, sql, nr_columns: 2, max_args: 999)

    rows = [["quux", 1]]
    bulk.exec_for_rows(rows) do |rows_inserted|
      rows_inserted.should eq(1)
    end

    db.exec "BEGIN"
    rows = (1..1000).map { ["quux", 1] }
    rows << ["sfdsf", 9]
    count = 0
    last_id = bulk.exec_for_rows(rows) do |rows_inserted|
      count += rows_inserted
    end
    count.should eq(rows.size)
    last_id.should eq(1002)
    db.exec "COMMIT"

    total = db.scalar "SELECT COUNT(*) FROM test"
    total.should eq(1002)
  end
end
