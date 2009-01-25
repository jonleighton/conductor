class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :author
  
  validates_presence_of :role
  
  # This creates an Authorship.build_from_authors method which we can pass a load of Authors and get
  # back a load of Authorships which are linked to those Authors.
  buildable_from :authors
  
  delegate :name, :to => :author, :prefix => true
  
  # Defining a sensible to_s is useful here, because if there are errors on an authorship the user
  # needs to be able to identify which one - the aggregated errors do this by calling to_s.
  def to_s
    author_name
  end
  
  # If there are errors and the form has to be re-rendered, we need a sensible definition of equality
  # so the currently unsaved authorships are used in the form rather than new ones - this means that
  # any changes the user has made are not lost.
  def ==(other)
    other.book_id == book_id && other.author_id == author_id
  end
end
