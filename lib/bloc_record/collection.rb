module BlocRecord
  class Collection < Array
    def update_all(updates)
      # take an array of updates and map over with a hash of updates
      ids = self.map(&:id)
      
      # check if there are any items i the array 
      self.any? ? self.first.class.update(ids, updates) : false
    end
  end
end