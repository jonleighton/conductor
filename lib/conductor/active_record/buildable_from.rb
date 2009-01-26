# This module is mixed into ActiveRecord::Base
module Conductor::ActiveRecord::BuildableFrom
  # This is most easily shown with an example:
  #
  #   class Membership < ActiveRecord::Base
  #     buildable_from :members
  #   end
  # 
  #   member = Person.find(:first)
  #   member.id # => 622
  # 
  #   membership = Membership.build_from_member(member)
  #   membership.member_id # => 622
  # 
  # Also, <tt>Membership.build_from_members(member1, member2, member3, ...)</tt> is provided which
  # returns an array of memberships.
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
