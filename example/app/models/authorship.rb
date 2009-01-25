class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :author
  
  validates_presence_of :role
  
  buildable_from :authors
  
  delegate :name, :to => :author, :prefix => true
  
  def to_s
    author_name
  end
  
  def ==(other)
    other.book_id == book_id && other.author_id == author_id
  end
end
