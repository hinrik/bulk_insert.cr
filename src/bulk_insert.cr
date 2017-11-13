require "db"

class BulkInsert
  VERSION = "0.1.0"

  alias NrRows = Int32
  @statements = {} of NrRows => DB::PoolStatement
  DEFAULT_MAX_ARGS = 999 # SQLite's maximum. Pg and MySQL have higher limits

  # Example:
  #
  #   BulkInsert.new(db, "INSERT INTO table (col1, col2) VALUES", 2)
  def initialize(db, sql_start, nr_columns, max_args = DEFAULT_MAX_ARGS)
    template = "(#{ (1..nr_columns).map { %[?] }.join(%[,]) })"

    nr_args = max_args - max_args % nr_columns
    while nr_args >= nr_columns
      nr_rows = nr_args / nr_columns
      sql = "#{sql_start} #{ (1..nr_rows).map { template }.join(%[, ]) }"
      @statements[nr_rows] = db.build sql
      nr_args /= 2
      nr_args -= nr_args % nr_columns
    end
  end

  def exec(row)
    @statements[1].exec(row)
  end

  # Example:
  #
  #   [["foo", 4], ["bar", 5]]
  #   lk.exec_many(rows) do |nr_rows, result|
  #     update_progress(nr_rows)
  #   end
  def exec_many(rows)
    remaining = rows.size

    all_nr_rows = @statements.keys
    i = 0
    while remaining > 0
      nr_rows = all_nr_rows[i]
      statement = @statements[nr_rows]
      if nr_rows > remaining
        i += 1
        next
      end

      position = rows.size - remaining
      args = rows[position...position+nr_rows].flatten
      yield nr_rows, statement.exec(args)
      remaining -= nr_rows
    end
  end

  def exec_many(rows)
    exec_many(rows) {}
  end
end

