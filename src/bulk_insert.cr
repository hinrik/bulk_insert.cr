class BulkInsert
  VERSION = "0.1.0"

  alias NrRows = Int32
  @statements = {} of NrRows => String
  DEFAULT_MAX_ARGS = 999 # SQLite's maximum. Pg and MySQL have higher limits

  # Example:
  #
  #   BulkInsert.new(2, "INSERT INTO table (col1, col2) VALUES")
  def initialize(nr_columns, sql_prefix, sql_suffix = "", max_args = DEFAULT_MAX_ARGS)
    template = "(#{ (1..nr_columns).map { %[?] }.join(%[,]) })"

    nr_args = max_args - max_args % nr_columns
    while nr_args >= nr_columns
      nr_rows = nr_args / nr_columns
      sql = "#{sql_prefix} #{ (1..nr_rows).map { template }.join(%[, ]) } #{sql_suffix}"
      @statements[nr_rows] = sql
      nr_args /= 2
      nr_args -= nr_args % nr_columns
    end
  end

  def exec(db, row)
    db.exec @statements[1], row
  end

  # Example:
  #
  #   [["foo", 4], ["bar", 5]]
  #   bulk.exec_many(db, rows) do |nr_rows, result|
  #     update_progress(nr_rows)
  #   end
  def exec_many(db, rows)
    remaining = rows.size

    all_nr_rows = @statements.keys
    i = 0
    while remaining > 0
      nr_rows = all_nr_rows[i]
      sql = @statements[nr_rows]
      if nr_rows > remaining
        i += 1
        next
      end

      position = rows.size - remaining
      args = rows[position...position+nr_rows].flatten
      yield nr_rows, db.exec(sql, args)
      remaining -= nr_rows
    end
  end

  def exec_many(db, rows)
    exec_many(db, rows) {}
  end
end

