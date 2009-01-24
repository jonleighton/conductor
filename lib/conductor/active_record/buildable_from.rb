module Conductor::ActiveRecord::BuildableFrom
  def buildable_from(plural_association_name)
    plural_association_name = plural_association_name.to_s
    association_name        = plural_association_name.singularize
    
    class_eval <<-STR
      def self.build_from_#{association_name}(item)                 # def build_from_author(item)
        returning new do |record|                                   #   returning new do |record|
          record.#{association_name}_id = item.id                   #     record.author_id = item.id
        end                                                         #   end
      end                                                           # end
      
      def self.build_from_#{plural_association_name}(*items)        # def build_from_authors(*items)
        items.map { |item| build_from_#{association_name}(item) }   #   items.map { |item| build_from_author(item) }
      end                                                           # end
    STR
  end
end
