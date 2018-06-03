require 'bloc_record/utility'
require 'bloc_record/schema'
require 'bloc_record/persistence'
require 'bloc_record/selection'
require 'bloc_record/connection'

module BlocRecord 
  class Base
    # include allows us to access instance methods
    include Persistence
    extend Selection
    extend Schema
    extend Connection
  
    def initialize(options={})
      options = BlocRecord::Utility.convert_keys(options)

      self.class.columns.each do |col|
        # send col name to attr_accessor and creates
        # an instance var for each col
        self.class.send(:attr_accessor, col)

        # set instance var to the value corresponding to
        # the key
        self.instance_variable_set("@#{col}", options[col])
      end
    end
  end
end