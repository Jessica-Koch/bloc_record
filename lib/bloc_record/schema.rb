require 'sqlite3'
require 'bloc_record/utility'

module Schema
  # returns table name in proper format
  def table 
    BlocRecord::Utility.underscore(name)
  end

  # return key value representation of table
  def schema 
    unless @schema 
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"]] = col["type"]
      end
    end
    @schema
  end

  # return column names of table
  def columns
    schema.keys
  end

  # return all column names EXCEPT id
  def attributes
    columns - ["id"]
  end

  # returns count of records in table
  def count 
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL
  end
end