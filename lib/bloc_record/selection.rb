require 'sqlite3'

module Selection
  # find multiple entries
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        WHERE id IN (#{ids.join(',')});
      SQL

      rows_to_array(rows)
    end
  end

  def my_map(arr)
    new_array = []
    for element in arr
     new_array.push yield element
    end

    new_array
  end

  def find_each(options, &block)
    batch_size = options.delete(:batch_size) || 100

    ind_in_batches(batch_size).each {|row| yield(row)}
  end

  def find_in_batches(batch_size, &block)

    rows = connection.get_first_row <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        LIMIT #{batch_size}
      SQL

      rows_to_array(rows)
  end

  # finds exact record by id
  # ex. character = Character.find(7)
  def find_one(id)
    if (id.is_a? String && !(!!(id =~  /(^-)/)))
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ','} FROM #{table}
        WHERE id = #{id};
      SQL
    
      init_object_from_row(row)
    else
      puts 'Invalid input'
    end
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
       SELECT #{columns.join ','} FROM #{table}
       WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
     SQL

    rows_to_array(rows)
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^find_by_(.*)$/
      find_by($1.to_sym, arguments.first)
    else
      super
    end
  end

  def respond_to_missing?(method_sym, include_private = false)
    if method_sym.to_s =~ /^find_by_(.*)$/
      true    
    else
      super
    end
  end

  def take(num = 1)
    user_num = Integer(gets) rescue false

    if user_num > 1
      rows = connection.execute <<-SQL
          SELECT #{columns.join ','} FROM #{table}
          ORDER BY random()
          LIMIT #{user_num};
        SQL
      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = conection.get_first_row <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ','} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash 
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ','} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      args =  args.map do |a| 
        if a.class == Hash
          hash_to_string(a)
        else 
          a.to_s
        end
      order = args.join(",")
    else 
      order = order.first.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when Hash
        joins = args.map do |arg| 
          "INNER JOIN #{arg.keys.first} ON #{arg.keys.first}.#{table}_id = #{table}.id"
          "INNER JOIN #{arg.values.first} ON #{arg.values.first}.#{arg.keys.first}_id = #{arg.keys.first}.id"
        end
        
        joins = joins.join(" ")
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{joins}
        SQL
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      end

 
    rows_to_array(rows)
  end

  private
  def asc_or_desc(str)
    if !!/\bdesc\b/i.match('desc')
      'DESC'
    elsif !!/\basc\b/i.match('asc')
      'ASC'
    else 
      return
    end
  end

  def hash_to_string(h)
     return a.map{|k,v| [k.to_s, v.to_s]}.join(' ')
  end

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
