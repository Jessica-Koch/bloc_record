module BlocRecord
  class Collection < Array
    def update_all(updates)
      # take an array of updates and map over with a hash of updates
      ids = self.map(&:id)
      
      # check if there are any items in the array 
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num=1)
      self.any? ? self.take(num) : false
    end

    def where(*args)
      self.any? ? self.first.where(args) : false
    end

    def not(*args)
      self.any? ? self.first.not(args) : false
    end

    def destroy_all
      self.any? ? self.destroy_all : false
    end
  end
end