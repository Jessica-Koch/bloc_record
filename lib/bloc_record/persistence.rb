require 'sqlite3'
require 'pg'
require 'bloc_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  # rescue from failed attempts to save
  def save
    self.save! rescue false
  end

  def save!
    # sets an id on the object if it is not present
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      # reload object to save to DB
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    # will be comma-delimited string of col names & values
    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"}.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL
    # indicate success
    true
  end

  def update_attribute(attribute, value)
    self.class.update(self.id, {attribute => value})
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^update_attribute_(.*)$/
      update_attribute($1.to_sym, arguments.first)
    else 
      super
    end
  end

  def respond_to_missing?(method_sym, include_private = false)
    if method_sym.to_s =~ /^update_attribute_(.*)$/
      true
    else 
      super
    end
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  def destroy 
    self.class.destroy(self.id)
  end

  module ClassMethods
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map {|key| BlocRecord::Utility.sql_strings(attrs[key]) }

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)
      updates = unless updates.empty? BlocRecord::Utility.convert_keys(updates)
      updates.delete "id"
      updates_array = updates.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}
      where_clause = id.nil? ? ";" : "WHERE id = #{id};"
      
       
      if ids.class == Fixnum
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ":" : "Where id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end
      
      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array + ","} #{where_clause}
      SQL

      true
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end
      
      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL
      true
    end

    def destroy_all(args=nil)
      if args.class == String
        args = args.split('=')
      end
      
      if args.class == Array
        args = args.map{|str| str.delete("'").tr('?','').tr('=','').strip}.each_slice(2).to_a.to_h
      end

      if args && !args.empty?
        args = BlocRecord::Utility.convert_keys(args)
        conditions = args.map{|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

        connection.exectute <<-SQL
          DELETE FROM #{table} 
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end

      true
    end

  end
end