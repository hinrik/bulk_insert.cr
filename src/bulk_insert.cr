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

  # Example:
  #
  #   [["foo", 4], ["bar", 5]]
  #   bulk.exec_for_rows(rows) do |nr_rows|
  #     update_progress(nr_rows)
  #   end
  def exec_for_rows(rows)
    remaining = rows.size

    all_nr_rows = @statements.keys
    i = 0
    last_id = nil
    while remaining > 0
      nr_rows = all_nr_rows[i]
      statement = @statements[nr_rows]
      if nr_rows > remaining
        i += 1
        next
      end

      position = rows.size - remaining
      args = rows[position...position+nr_rows].flatten
      result = statement.exec args
      last_id = result.last_insert_id if result.responds_to? :last_insert_id
      remaining -= nr_rows
      yield nr_rows
    end

    last_id
  end

  def exec_for_rows(rows)
    exec_for_rows(rows) {}
  end
end

