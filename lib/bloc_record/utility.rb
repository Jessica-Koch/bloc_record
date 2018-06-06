module BlocRecord
  module Utility
    # self is Utility Class – underscore will be a 
    # class method instead of an instance method
    extend self 

    def camel(snake_cased_word)
      snake_cased_word.gsub(/^\w|_\w/) { |m| m[-1, 1].upcase}
    end

    def underscore(camel_cased_word)
      # replace any double colons with slashes
      string = camel_cased_word.gsub(/::/, '/')

      # insert an underscore between any all-caps class 
      # prefixes(acronyms) and other words
      string.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')

      # insert an underscore between camel-cased words
      string.gsub!(/([a-z\d])([A-Z])/, '\1_\2')

      # replace any - with _ using tr
      string.tr!("-", "_")
      string.downcase
    end 

    # converts String or Numeric to a SQL string
    def sql_strings(value)
      case value
      when String
        "'#{value}'"
      when Numeric
        value.to_s
      else 
        "null"
      end
    end

    # takes options hash and returns hash with strings as keys.
    def convert_keys(options)
      options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
      options
    end

    # converts instance vars to Hash
    def instance_variables_to_hash(obj)
      Hash[obj.instance_variables.map{ |var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)]}]
    end

    # overwrites the instance var values with stored 
    # values from DB – discards unsaved changes to obj
    def reload_obj(dirty_obj)
      persisted_obj = dirty_obj.class.find_one(dirty_obj.id)
      dirty_obj.instance_variables.each do |instance_variable|
        dirty_obj.instance_variable_set(instance_variable, persisted_obj.instance_variable_get(instance_variable))
      end
    end

  end
end