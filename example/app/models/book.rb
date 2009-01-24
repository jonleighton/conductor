class Book < ActiveRecord::Base
  belongs_to :publisher
  
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships
  
  has_and_belongs_to_many :tags
  
  validates_presence_of :name
  validates_presence_of :publisher_id, :message => "must exist"
  
  def potential_authorships
    authorships.build_from_authors(*Author.find(:all))
  end
  
  def potential_publishers
    Publisher.find(:all)
  end
  
  def potential_tags
    Tag.find(:all)
  end
  
  def publisher_name
    publisher.name
  end
end
