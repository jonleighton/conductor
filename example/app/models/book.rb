class Book < ActiveRecord::Base
  belongs_to :publisher
  
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships
  
  validates_presence_of :name
  validates_presence_of :publisher_id, :message => "must exist"
  
  def potential_authors
    Author.find(:all)
  end
  
  def potential_authorships
    authorships.from_authors(*potential_authors)
  end
end
