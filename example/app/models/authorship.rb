class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :author
  
  validate :validate_presence_of_role
  
  buildable_from :authors
  
  def ==(other)
    other.book_id == book_id && other.author_id == author_id
  end
  
  def author_name
    author.name
  end
  
  private
  
    def validate_presence_of_role
      if role.blank?
        errors.add_to_base "You must specify the role for #{author.name}"
      end
    end
end
