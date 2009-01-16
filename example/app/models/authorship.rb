class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :author
  
  validate :validate_presence_of_role
  
  def self.from_authors(*authors)
    authors.map do |author|
      new do |authorship|
        authorship.author_id = author.id
      end
    end
  end
  
  def ==(other)
    other.book_id == book_id && other.author_id == author_id
  end
  
  private
  
    def validate_presence_of_role
      if role.blank?
        errors.add_to_base "You must specify the role for #{author.name}"
      end
    end
end
